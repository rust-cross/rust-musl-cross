use std::env;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::str;

use argh::FromArgs;

#[derive(FromArgs)]
/// Compile LLVM libunwind
struct Opts {
    /// build for the target triple
    #[argh(option)]
    target: String,

    /// llvm libunwind source directory
    #[argh(positional)]
    source_dir: PathBuf,

    /// output directory
    #[argh(positional)]
    output_dir: PathBuf,
}

fn get_host_target() -> Result<String, String> {
    let output = Command::new("rustc").arg("-vV").output();
    let output = match output {
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => {
            return Err(
                "rustc, the rust compiler, is not installed or not in PATH. \
                This package requires Rust and Cargo to compile extensions. \
                Install it through the system's package manager or via https://rustup.rs/."
                    .to_string(),
            );
        }
        Err(err) => {
            return Err(format!(
                "Failed to run rustc to get the host target: {:?}",
                err
            ));
        }
        Ok(output) => output,
    };

    let output = str::from_utf8(&output.stdout).unwrap();

    let field = "host: ";
    let host = output
        .lines()
        .find(|l| l.starts_with(field))
        .map(|l| &l[field.len()..])
        .ok_or_else(|| {
            format!(
                "`rustc -vV` didn't have a line for `{}`, got:\n{}",
                field.trim(),
                output
            )
        })?
        .to_string();
    Ok(host)
}

fn compile(target: &str, source_dir: &Path, output_dir: &Path) {
    let host = get_host_target().unwrap();

    env::set_var("TARGET", target);
    env::set_var("HOST", &host);
    env::set_var("OPT_LEVEL", "3");

    let mut cc_cfg = cc::Build::new();
    let mut cpp_cfg = cc::Build::new();

    cpp_cfg.cpp(true);
    cpp_cfg.cpp_set_stdlib(None);
    cpp_cfg.flag("-nostdinc++");
    cpp_cfg.flag("-fno-exceptions");
    cpp_cfg.flag("-fno-rtti");
    cpp_cfg.flag_if_supported("-fvisibility-global-new-delete-hidden");

    // Don't set this for clang
    // By default, Clang builds C code in GNU C17 mode.
    // By default, Clang builds C++ code according to the C++98 standard,
    // with many C++11 features accepted as extensions.
    if cpp_cfg.get_compiler().is_like_gnu() {
        cpp_cfg.flag("-std=c++11");
        cc_cfg.flag("-std=c99");
    }

    if target.contains("x86_64-fortanix-unknown-sgx") || target.contains("musl") {
        // use the same GCC C compiler command to compile C++ code so we do not need to setup the
        // C++ compiler env variables on the builders.
        // Don't set this for clang++, as clang++ is able to compile this without libc++.
        if cpp_cfg.get_compiler().is_like_gnu() {
            cpp_cfg.cpp(false);
        }
    }

    for cfg in [&mut cc_cfg, &mut cpp_cfg].iter_mut() {
        cfg.target(target);
        cfg.host(&host);
        cfg.out_dir(output_dir);
        cfg.warnings(false);
        cfg.debug(false);
        cfg.flag("-fstrict-aliasing");
        cfg.flag("-funwind-tables");
        cfg.flag("-fvisibility=hidden");
        cfg.define("_LIBUNWIND_DISABLE_VISIBILITY_ANNOTATIONS", None);
        cfg.include(source_dir.join("include"));
        cfg.cargo_metadata(false);

        if target.contains("x86_64-fortanix-unknown-sgx") {
            cfg.static_flag(true);
            cfg.opt_level(3);
            cfg.flag("-fno-stack-protector");
            cfg.flag("-ffreestanding");
            cfg.flag("-fexceptions");

            // easiest way to undefine since no API available in cc::Build to undefine
            cfg.flag("-U_FORTIFY_SOURCE");
            cfg.define("_FORTIFY_SOURCE", "0");
            cfg.define("RUST_SGX", "1");
            cfg.define("__NO_STRING_INLINES", None);
            cfg.define("__NO_MATH_INLINES", None);
            cfg.define("_LIBUNWIND_IS_BAREMETAL", None);
            cfg.define("__LIBUNWIND_IS_NATIVE_ONLY", None);
            cfg.define("NDEBUG", None);
        }
    }

    let mut c_sources = vec![
        "Unwind-sjlj.c",
        "UnwindLevel1-gcc-ext.c",
        "UnwindLevel1.c",
        "UnwindRegistersRestore.S",
        "UnwindRegistersSave.S",
    ];

    let cpp_sources = vec!["Unwind-EHABI.cpp", "Unwind-seh.cpp", "libunwind.cpp"];
    let cpp_len = cpp_sources.len();

    if target.contains("x86_64-fortanix-unknown-sgx") {
        c_sources.push("UnwindRustSgx.c");
    }

    for src in c_sources {
        cc_cfg.file(source_dir.join("src").join(src).canonicalize().unwrap());
    }

    for src in cpp_sources {
        cpp_cfg.file(source_dir.join("src").join(src).canonicalize().unwrap());
    }

    cpp_cfg.compile("unwind-cpp");

    let mut count = 0;
    for entry in std::fs::read_dir(&output_dir).unwrap() {
        let obj = entry.unwrap().path().canonicalize().unwrap();
        if let Some(ext) = obj.extension() {
            if ext == "o" {
                cc_cfg.object(&obj);
                count += 1;
            }
        }
    }
    assert_eq!(
        cpp_len, count,
        "Can't get object files from {:?}",
        &output_dir
    );
    cc_cfg.compile("unwind");
}

fn main() {
    let opt: Opts = argh::from_env();
    compile(&opt.target, &opt.source_dir, &opt.output_dir);
}
