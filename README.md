Change player privileges even when they are not logged in.
==

This mod allows you create automatic assignments of privileges. Currently privileges are granted or revoked whenever a player logs in.

Syntax

```
/privafk (grant|revoke|reset|list) <privilege>
```
`grant <privilege>`

When a player joins and doesn't have this privilege grant it to them. This also applies the privilege to all logged in players immediately.

`revoke <privilege>`:

When a player joins and has this privilege, revoke it. This also revokes the privilege for all logged in players immediately.

`reset <privilege>`:

Remove the automated assignment for this privilege. This only prevents the further granting/revoking of this privilege. It does not affect already existing privileges.

`list`:

List the current setup. Privileges that are auto-granted are prefixed with a "+" and those that are auto-revoked are prefixed with "-".
