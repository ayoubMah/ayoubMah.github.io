---
title: Fixing Flyway Database Connection Errors in Docker
date: 2025-11-20T12:19:05+01:00
draft: false
tags: []
categories:
  - blog
  - Docker
  - java
  - PostgreSQL
---


Before reading this blog i suggest you have a quick look at how *Docker Compose starts services* especially how databases take time to initialize before they start accepting connections.  

so basically, when you work with microservices, each service has its own database (in my case: patient-db, doctor-db…). and when Spring Boot starts, Flyway tries to run the migration scripts immediately.

But there is a problem:

*Flyway is much faster than PostgreSQL.*  
PostgreSQL says: “I’m starting…”  
Flyway says: “I want to connect now.”  
PostgreSQL says: “Wait wait wait hold on…”  
Flyway says: “Connection refused.”

And then your whole service crashes.

#  *The Real Error (exactly as I got it)*

Here is the full Flyway error message I faced during development:
```bash
Caused by: org.flywaydb.core.internal.exception.sqlExceptions.FlywaySqlUnableToConnectToDbException: Unable to obtain connection from database: Connection to doctor-db:5432 refused. Check that the hostname and port are correct and that the postmaster is accepting TCP/IP connections. SQL State  : 08001 Error Code : 0 Message    : Connection to doctor-db:5432 refused. Check that the hostname and port are correct and that the postmaster is accepting TCP/IP connections. at org.flywaydb.core.internal.jdbc.JdbcUtils.openConnection(JdbcUtils.java:70)  ... Caused by: org.postgresql.util.PSQLException: Connection to doctor-db:5432 refused. Check that the hostname and port are correct and that the postmaster is accepting TCP/IP connections.

```

This is the typical Flyway + Docker startup problem.  
If you see *Connection refused*, the database hasn’t finished booting yet.

# *Why This Happens*

This is a *race condition*:

1. Docker starts my PostgreSQL container
    
2. PostgreSQL begins initializing (this can take 3–8 seconds, longer if the volume is empty)
    
3. Docker immediately starts your Spring Boot service
    
4. Spring Boot runs Flyway migrations
    
5. Flyway tries to connect to the database *too early*
    
6. PostgreSQL is still preparing files, users, and permissions
    
7. Connection refused → Flyway crashes → Spring crashes
    

#  *Quick Fix => Just Restart the Services :) *

If the database is fully initialized now, just restart the services:

docker compose restart doctor-service patient-service

This works, but it’s not a clean or professional solution.

#  *Real Fix*

Prevent this problem forever.

We use *healthchecks*.

### Add a Healthcheck to your databases
```yaml
patient-db: # my use case
   image: postgres:15
   environment:     
	   POSTGRES_DB: patientdb     
	   POSTGRES_USER: postgres     
	   POSTGRES_PASSWORD: password   
   healthcheck:     
	   test: ["CMD-SHELL", "pg_isready -U postgres"]     
	   interval: 5s     
	   timeout: 5s     
	   retries: 5
```

### Update depends_on

```yaml
patient-service:   
	depends_on:     
		patient-db:      
			condition: service_healthy

```

iwa Allah yja3al lbaraka :)