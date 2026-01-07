## Windows Command Line Best Practices

**CRITICAL: Avoid `>nul` and `2>nul` redirections on Windows**

On Windows, redirecting to `nul` can create a literal file named "nul" instead of redirecting to the NUL device. These files are extremely difficult to delete and cause repository issues.

**Problem commands:**

```cmd
findstr /s /i "pattern" "*.cpp" "*.h" 2>nul
command 2>nul | head -20
any-command >nul
```

**Safe alternatives:**

1. **Don't suppress errors** - Let error output show naturally
2. **Use full device path**: `2>\\.\NUL` (works reliably but verbose)
3. **Use PowerShell** for cross-platform compatibility where applicable
4. **Prefer dedicated tools** over piped bash commands (use Grep, Glob, Read tools instead)

**Examples of safe patterns:**

```cmd
# Bad: Creates nul file
findstr /s /i "DD_TRACE" "*.cpp" 2>nul
# Good: Let errors show
findstr /s /i "DD_TRACE" "*.cpp"
# Good: Use full device path if suppression is essential
findstr /s /i "DD_TRACE" "*.cpp" 2>\\.\NUL
```

**Reference:** See https://github.com/anthropics/claude-code/issues/4928 for details on this Windows limitation.
