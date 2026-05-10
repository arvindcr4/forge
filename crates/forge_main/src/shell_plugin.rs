use std::io::{BufRead, BufReader};
use std::path::PathBuf;
use std::process::Stdio;

use anyhow::{Context, Result};

fn normalize_script(content: &str) -> String {
    content.replace("\r\n", "\n").replace('\r', "\n")
}

fn push_script(output: &mut String, content: &str) {
    output.push_str(&normalize_script(content));
    if !output.ends_with('\n') {
        output.push('\n');
    }
}

pub(crate) fn generate_fish_plugin() -> String {
    let mut output = String::new();

    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/conf.d/forge.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_exec.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_log.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_action_new.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_action_info.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_action_conversation.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_action_model.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_action_commit.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_action_doctor.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_action_default.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/functions/_forge_dispatcher.fish"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-fish/completions/forge.fish"),
    );
    output.push_str("\nset -gx _FORGE_PLUGIN_LOADED (date +%s)\n");

    output
}

pub(crate) fn generate_fish_theme() -> String {
    normalize_script(include_str!("../../../shell-plugin-fish/forge.theme.fish"))
}

pub(crate) fn fish_plugin_path() -> Result<PathBuf> {
    let home = std::env::var("HOME").context("HOME environment variable not set")?;
    Ok(PathBuf::from(home)
        .join(".local")
        .join("share")
        .join("forge")
        .join("shell-plugin-fish")
        .join("forge.plugin.fish"))
}

pub(crate) fn generate_pwsh_plugin() -> String {
    let mut output = String::new();

    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/config.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/helpers.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/core.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/config.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/conversation.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/git.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/auth.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/editor.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/provider.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/doctor.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/actions/keyboard.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/dispatcher.ps1"),
    );
    push_script(
        &mut output,
        include_str!("../../../shell-plugin-pwsh/lib/completion.ps1"),
    );
    output.push_str("\n$script:ForgePluginLoaded = $true\n$env:_FORGE_PLUGIN_LOADED = \"1\"\n");

    output
}

pub(crate) fn generate_pwsh_theme() -> String {
    normalize_script(include_str!("../../../shell-plugin-pwsh/forge.theme.ps1"))
}

pub(crate) fn run_fish_doctor() -> Result<()> {
    execute_script_with_streaming(
        "fish",
        &["-c"],
        include_str!("../../../shell-plugin-fish/doctor.fish"),
        "fish doctor",
    )
}

pub(crate) fn run_fish_keyboard() -> Result<()> {
    execute_script_with_streaming(
        "fish",
        &["-c"],
        include_str!("../../../shell-plugin-fish/keyboard.fish"),
        "fish keyboard",
    )
}

pub(crate) fn run_pwsh_doctor() -> Result<()> {
    execute_script_with_streaming(
        "pwsh",
        &["-NoProfile", "-Command"],
        include_str!("../../../shell-plugin-pwsh/doctor.ps1"),
        "PowerShell doctor",
    )
}

pub(crate) fn run_pwsh_keyboard() -> Result<()> {
    execute_script_with_streaming(
        "pwsh",
        &["-NoProfile", "-Command"],
        include_str!("../../../shell-plugin-pwsh/keyboard.ps1"),
        "PowerShell keyboard",
    )
}

fn execute_script_with_streaming(
    program: &str,
    prefix_args: &[&str],
    script_content: &str,
    script_name: &str,
) -> Result<()> {
    let script_content = normalize_script(script_content);
    let mut command = std::process::Command::new(program);
    command.args(prefix_args).arg(script_content);

    let mut child = command
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .context(format!("Failed to execute {script_name} script"))?;

    let stdout = child.stdout.take().context("Failed to capture stdout")?;
    let stderr = child.stderr.take().context("Failed to capture stderr")?;

    std::thread::scope(|s| {
        s.spawn(|| {
            let stdout_reader = BufReader::new(stdout);
            for line in stdout_reader.lines() {
                match line {
                    Ok(line) => println!("{line}"),
                    Err(e) => eprintln!("Error reading stdout: {e}"),
                }
            }
        });

        s.spawn(|| {
            let stderr_reader = BufReader::new(stderr);
            for line in stderr_reader.lines() {
                match line {
                    Ok(line) => eprintln!("{line}"),
                    Err(e) => eprintln!("Error reading stderr: {e}"),
                }
            }
        });
    });

    let status = child
        .wait()
        .context(format!("Failed to wait for {script_name} script"))?;

    if !status.success() {
        let exit_code = status
            .code()
            .map_or_else(|| "unknown".to_string(), |code| code.to_string());
        anyhow::bail!("{script_name} script failed with exit code: {exit_code}");
    }

    Ok(())
}
