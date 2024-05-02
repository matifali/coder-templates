$task = @{
        TaskName = 'CoderAgent'
        Action = (New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-sta -ExecutionPolicy Unrestricted -Command "$env:CODER_AGENT_TOKEN_FILE=\'C:\OEM\token\'; & C:\OEM\CoderAgent.ps1 *>>  C:\OEM\CoderAgent.log"')
        Trigger = (New-ScheduledTaskTrigger -AtStartup), (New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(15))
        Settings = (New-ScheduledTaskSettingsSet -DontStopOnIdleEnd -ExecutionTimeLimit ([TimeSpan]::FromDays(3650)) -Compatibility Win8)
        Principal = (New-ScheduledTaskPrincipal -UserId 'vm\coder' -RunLevel Highest -LogonType S4U)
}
Register-ScheduledTask @task -Force