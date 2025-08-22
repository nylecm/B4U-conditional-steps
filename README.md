# B4U

B4U is a configurable multithreaded task runner designed to integrate into any git project. It allows you to implement your own quality checks before git actions (commits, pushes, etc.).

B4U is intended to be fast, configurable and (importantly) not annoying.

## Quick Start

1. **Install:** `gem install B4U`
2. **Initialize:** `B4U --init`
3. **Configure tasks** in `.B4U/commit.yml` and `.B4U/push.yml`
4. **Commit these files** to your version control
5. **Team setup:** `B4U --enable` (after cloning)

## Installation

Install the gem:

```bash
gem install B4U
```

Or add to your Gemfile:

```ruby
bundle add B4U
```

## Configuration

B4U uses YAML configuration files in the `.B4U` directory:

- `.B4U/commit.yml` - Tasks to run before commits
- `.B4U/push.yml` - Tasks to run before pushes

### Configuration Format

Each task requires a `name` and `command`. Optionally add `ignore: true` for non-blocking tasks:

```yaml
linters:
  - name: "Unit tests"
    command: "bundle exec rspec"
    ignore: true  # Won't block commit if this fails
  - name: "Rubocop"
    command: "bundle exec rubocop"
  - name: "ESLint"
    command: "npm run lint"
  - name: "Type checking"
    command: "npm run type-check"
```

**Important:** Tasks run in parallel, so only use read-only commands to avoid conflicts.

## Usage

### Command Line Options

```bash
B4U --help     # Show help
B4U --version  # Show version
B4U --init     # Initialize B4U in current project
B4U --enable   # Enable B4U hooks in current project
B4U --commit   # Run pre-commit tasks
B4U --push     # Run pre-push tasks
```

## Setup

Running `B4U --init` will:
- Create a `.B4U` directory with configuration files.
- Set up git hooks for pre-commit and pre-push events.

Running `B4U --enable` will:
- Set up your local git hooks for pre-commit and pre-push events.

**Important:** Anyone who clones the project needs to run `B4U --enable` to activate the hooks locally so should add this to your setup script and/or README.md.

## Troubleshooting

**"Command not found: B4U"**
- If you're seeing this error and you already have installed B4U, it is likely caused by your IDE or version manager.

  B4U runs by calling itself from the shell scripts in the `.B4U` folder, so you can add any logic needed to point to the correct version of Ruby or even install the gem to the current version. 

## Contributing

Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration.

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -am 'Add amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

Please make sure to update tests as appropriate and adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the B4U project's codebases, issue trackers, and discussions is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).