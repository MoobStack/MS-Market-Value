# MS Market Value 1.3.0 beta — Test revision 6

Same version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Include 1,848 Everloot rates across 238 creature/harvesting entries. Reference data is the default, with personal collection on and missing drops filled from your own samples.
- Label the small farming display **Rate** and **Session**. Session value is shown by default; **Farming settings → Show session total** hides its line.
- Put **Idle** or **Paused** beside the hourly rate. Both figures freeze during a pause; your next farming receipt resumes an idle session. Manual pauses remain manual.

Close WoW and replace `MSMarketValue` using the Clean ZIP. Keep SavedVariables. Disable the old `MSMarketValueReference` pilot, which would replace the bundled database. Check `/msmv diagnostics` says **Test revision: 6**.

Coverage is partial and based on community samples, not verified server settings. The data adds about 11 KiB of runtime Lua, decodes only viewed sources and is not copied into SavedVariables. Source credit, the export and update instructions are in the full repository.

Check reference/personal switching, the session-total option, idle resume and a manual pause in Forever. This remains a beta; no official 1.3 release was published.
