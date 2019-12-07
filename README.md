Change privileges for all players.
==

This is a mod for the game Minetest. It allows you create automatic assignments of privileges. Currently privileges are granted or revoked whenever a player logs in.

Syntax

```
/privall (grant|revoke|reset|list) <privilege> ...
```
`grant <privilege> ...`

Grant the specified privileges to all online players immediately. If a player does not have this privilege after this call has been made then it will be granted to them the next time they log in.

`revoke <privilege> ...`:

Revoke the specified privileges from all online players immediately. If a player has this privilege after this call has been made then it will be revoked from them the next time they log in.

`reset <privilege> ...`:

Remove the automated assignment for these privileges. This only prevents the further granting/revoking of these privileges. It does not affect already existing ones.

`list`:

List the current setup. Privileges that are auto-granted are prefixed with a "+" and those that are auto-revoked are prefixed with "-".
