//! A minimal binary that prints a greeting.

fn main() {
    println!("{}", greeting("world"));
}

/// Builds the greeting shown to `name`.
fn greeting(name: &str) -> String {
    format!("Hello, {name}!")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greets_by_name() {
        assert_eq!(greeting("world"), "Hello, world!");
    }
}
