import re
import subprocess
from datetime import UTC, datetime

import humanize
from tabulate import tabulate

data: dict[str, dict[str, str]] = {}
now = datetime.now(tz=UTC)

for line in (
    subprocess.check_output(
        [
            "colmena",
            "exec",
            ";".join(  # noqa: FLY002
                [
                    "echo selected: $(readlink -f /nix/var/nix/profiles/system | xargs stat -c %Z)",
                    "echo booted: $(readlink -f /run/booted-system | xargs stat -c %Z)",
                ]
            ),
        ],
        stderr=subprocess.STDOUT,
    )
    .decode()
    .splitlines()
):
    if not (m := re.match(r"(\S+) \| (\S+): (.*)", line.strip())):
        continue
    host, key, value = m.groups()
    data.setdefault(host, {})
    data[host][key] = value


def when(ts: str):
    dt = datetime.fromtimestamp(int(ts), tz=UTC)
    if dt == now:
        return "now"
    h = humanize.time.naturaldelta(now - dt)
    if dt > now:
        return f"in {h}"
    return f"{h} ago"


print(
    tabulate(
        sorted(
            [
                dict(  # noqa: C408
                    host=host,
                    okay="okay"
                    if hostdata["booted"] == hostdata["selected"]
                    else "outdated",
                    booted=when(hostdata["booted"]),
                    selected=when(hostdata["selected"]),
                )
                for host, hostdata in data.items()
            ],
            key=lambda x: x["host"],
        ),
        headers="keys",
    )
)
