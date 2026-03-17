# PHP-FPM Dynamic Resource Allocation (70/30)

Script location: /root/scripts/set_php_limits.sh

## Logic
1. Reads total server RAM in MB.
2. Reserves 1500 MB for OS, Nginx, and CrowdSec.
3. Calculates the maximum safe PHP processes (assuming ~60MB per process).
4. Sets the `pm.max_children` value to exactly 70% of the available capacity for each pool.

## Goal
Ensures high performance during traffic bursts while strictly preventing any single user (pool) from consuming 100% of the server's CPU and RAM. The remaining 30% of resources are permanently reserved to keep other domains online and prevent 502/504 timeout errors during targeted attacks.
