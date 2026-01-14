use anyhow::{Context, Result};
use rustc_build_sysroot::{SysrootBuilder, SysrootConfig};
use std::env;
use std::ffi::OsString;
use std::path::PathBuf;
use std::process::Command;

fn main() -> Result<()> {
    // Get the target from command line arguments or environment
    let target = env::args()
        .nth(1)
        .or_else(|| env::var("TARGET").ok())
        .context("TARGET not specified")?;

    // Get rustflags from environment if set
    // Note: This uses split_whitespace(), so quoted arguments are not supported
    let rustflags_str = env::var("RUSTFLAGS").unwrap_or_default();
    let rustflags: Vec<OsString> = if rustflags_str.is_empty() {
        Vec::new()
    } else {
        rustflags_str
            .split_whitespace()
            .map(OsString::from)
            .collect()
    };

    // Get the sysroot source directory
    let rustc_output = Command::new("rustc")
        .args(["--print", "sysroot"])
        .output()
        .context("failed to run rustc --print sysroot to determine sysroot path")?;
    
    let sysroot_base = String::from_utf8_lossy(&rustc_output.stdout)
        .trim()
        .to_string();
    
    let src_dir = PathBuf::from(&sysroot_base)
        .join("lib")
        .join("rustlib")
        .join("src")
        .join("rust")
        .join("library");
    
    let sysroot_dir = PathBuf::from(&sysroot_base)
        .join("lib")
        .join("rustlib")
        .join(&target);

    println!("Building sysroot for target: {}", target);
    println!("Source directory: {}", src_dir.display());
    println!("Sysroot directory: {}", sysroot_dir.display());

    // Build the sysroot with std
    let mut builder = SysrootBuilder::new(&sysroot_dir, &target)
        .sysroot_config(SysrootConfig::WithStd {
            std_features: Vec::new(),
        });

    // Add rustflags if provided
    if !rustflags.is_empty() {
        println!("Using RUSTFLAGS: {:?}", rustflags);
        builder = builder.rustflags(rustflags);
    }

    builder.build_from_source(&src_dir)
        .context("failed to build sysroot from source")?;

    println!("Sysroot built successfully!");
    Ok(())
}
