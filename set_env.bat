@echo off
IF EXIST deployment.env (
    FOR /F "tokens=* delims=" %%G IN (deployment.env) DO (
        SET "%%G"
    )
)

IF EXIST secrets.env (
    FOR /F "tokens=* delims=" %%G IN (secrets.env) DO (
        SET "%%G"
    )
)

IF EXIST .env (
    FOR /F "tokens=* delims=" %%G IN (.env) DO (
        SET "%%G"
    )
)