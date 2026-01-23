fn run() -> anyhow::Result<()> {
    env_logger::init();

    println!("GET https://www.rust-lang.org");

    let mut res = reqwest::blocking::get("https://www.rust-lang.org/en-US/")?;

    println!("Status: {}", res.status());
    println!("Headers:\n{:?}", res.headers());

    // copy the response body directly to stdout
    let _ = std::io::copy(&mut res, &mut std::io::stdout())?;

    println!("\n\nDone.");
    Ok(())
}

fn main() {
    run().unwrap();
}
