#!/bin/bash

THREAD_DUMP=$1
REPORT_FILE=$2
CONTEXT_INFO=$3

if [ -z "$THREAD_DUMP" ] || [ -z "$REPORT_FILE" ]; then
    echo "Core Error: Missing parameters for analysis."
    exit 1
fi

TOTAL_THREADS=$(echo "$THREAD_DUMP" | grep -c "^\"")
RUNNABLE=$(echo "$THREAD_DUMP" | grep -c "java.lang.Thread.State: RUNNABLE")
TIMED_WAITING=$(echo "$THREAD_DUMP" | grep -c "java.lang.Thread.State: TIMED_WAITING")
WAITING=$(echo "$THREAD_DUMP" | grep -c "java.lang.Thread.State: WAITING")
BLOCKED=$(echo "$THREAD_DUMP" | grep -c "java.lang.Thread.State: BLOCKED")

TOMCAT_TOTAL=$(echo "$THREAD_DUMP" | grep -c "http-nio")
HIKARI_TOTAL=$(echo "$THREAD_DUMP" | grep -c "HikariPool")
SPRING_SCHED=$(echo "$THREAD_DUMP" | grep -c "scheduling-")

DEADLOCK_CHECK=$(echo "$THREAD_DUMP" | grep -i "deadlock")
if [ -n "$DEADLOCK_CHECK" ]; then
    HEALTH_STATUS="CRITICAL (Deadlock detected)"
elif [ "$BLOCKED" -gt 5 ]; then
    HEALTH_STATUS="WARNING ($BLOCKED threads blocked)"
else
    HEALTH_STATUS="HEALTHY"
fi

{
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│             SPRING ENGINE HEALTH DASHBOARD             │"
    echo "└────────────────────────────────────────────────────────┘"
    echo "  Execution Date : $(date)"
    echo "$CONTEXT_INFO"
    echo "  Global Status  : $HEALTH_STATUS"
    echo "──────────────────────────────────────────────────────────"
    echo ""
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│ 1. JVM THREAD STATES                                   │"
    echo "└────────────────────────────────────────────────────────┘"
    printf "  %-20s : %d\n" "Total Threads" "$TOTAL_THREADS"
    printf "  %-20s : %d\n" "RUNNABLE (Active)" "$RUNNABLE"
    printf "  %-20s : %d\n" "TIMED_WAITING (Sleep)" "$TIMED_WAITING"
    printf "  %-20s : %d\n" "WAITING (Idle)" "$WAITING"
    printf "  %-20s : %d\n" "BLOCKED (Contention)" "$BLOCKED"
    echo ""
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│ 2. SPRING ECOSYSTEM POOLS                              │"
    echo "└────────────────────────────────────────────────────────┘"
    printf "  %-20s : %d threads active\n" "Tomcat (HTTP)" "$TOMCAT_TOTAL"
    printf "  %-20s : %d connections/threads\n" "HikariCP (Database)" "$HIKARI_TOTAL"
    printf "  %-20s : %d active runners\n" "Spring@Scheduled" "$SPRING_SCHED"
    echo ""
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│ 3. CRITICAL ALERTS                                     │"
    echo "└────────────────────────────────────────────────────────┘"
    if [ -n "$DEADLOCK_CHECK" ]; then
        echo "  [!!] DEADLOCK DETECTED BETWEEN THREADS:"
        echo "$THREAD_DUMP" | sed -n '/Found one Java-level deadlock:/,$p' | sed 's/^/  /'
    else
        echo "  [-] No Java-level deadlocks detected."
    fi
    echo ""
    if [ "$BLOCKED" -gt 0 ]; then
        echo "  [!] TOP BLOCKED THREADS DETAILS:"
        echo "$THREAD_DUMP" | grep "java.lang.Thread.State: BLOCKED" -B 1 -A 4 | head -n 20 | sed 's/^/  /'
    else
        echo "  [-] No thread severe blocking detected."
    fi
    echo ""
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│ 4. HOTSPOTS & BOTTLENECK CANDIDATES                    │"
    echo "└────────────────────────────────────────────────────────┘"
    echo "  (Most frequent business methods currently executing)"
    echo ""
    echo "$THREAD_DUMP" | grep "at " | grep -v -E "java.lang|java.util|sun.|jdk.|org.apache.tomcat|org.apache.catalina|org.apache.coyote|io.undertow|org.postgresql|com.mysql|com.zaxxer.hikari|org.springframework.web|org.springframework.aop|ch.qos.logback" | sort | uniq -c | sort -nr | head -n 10 | awk '{print "  Count: " $1 " \t-> " $2 " " $3}'
    echo ""
    echo "└────────────────────────────────────────────────────────┘"
} > "$REPORT_FILE"

cat "$REPORT_FILE"