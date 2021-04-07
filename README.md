# Fusion Studio API
[![Build Status](https://travis-ci.com/evolvedbinary/fusion-studio-api.svg?branch=master)](https://travis-ci.com/evolvedbinary/fusion-studio-api)
[![License](https://img.shields.io/badge/license-AGPL%203-blue.svg)](https://opensource.org/licenses/AGPL-3.0)

Server Side API for [Fusion Studio](https://github.com/evolvedbinary/fusion-studio) written in RESTXQ and XQuery.

Compatible with:
* [FusionDB Server](https://fusiondb.com) 1.0.0-ALPHA3 or newer
* [eXist-db](http://www.exist-db.org) 5.0.0 or newer

API documentation is here: https://app.swaggerhub.com/apis/evolvedbinary/fusion-studio-api/1.1.1

## Build Instructions

Requirements:
* Java's [JDK](https://openjdk.java.net/install/) 8+
* [Apache Maven](https://maven.apache.org/) 3.3+

```bash
$ git clone https://github.com/evolvedbinary/fusion-studio-api.git
$ cd fusion-studio-api
$ mvn clean package
```

This will create an EXPath package in `target/fusion-studio-api-x.y.z.xar`, which can be deployed to FusionDB (or eXist-db). 

## Test Instructions
By default tests are executed against the latest FusionDB nightly build running as a Docker Container.
For development purposes, it is also possible to execute the tests from an IDE such as IntelliJ against a locally installed FusionDB (or eXist-db) server.

Requirements:
* Docker
* Username/Password for accessing the FusionDB nightly build Docker repository.

Various settings of the build can be overridden using the following System Properties and Environment Variables:
| Purpose | System Property | Environment Variable |
|---------|-----------------|----------------------|
| Docker Repo Username | `docker.username` | N/A |
| Docker Repo Password | `docker.password` | N/A |
| Docker Database Image | `docker.db.image` | N/A |
| Host for Fusion Studio API | `api.host` | `API_HOST` |
| Port for Fusion Studio API | `api.port` | `API_PORT` |

**NOTE:** If you wish to use the FusionDB Nightly Build Docker Container, you must configure your username and password for the
repository in either your Maven Settings file (`~/.m2/settings.xml`), or provide the values via System Properties (see above).
For the Maven Settings file, the following should be added to the `<servers>` section:
```xml
<server>
    <id>repo.evolvedbinary.com:9543</id>
    <username>your-username</username>
    <password>your-password</password>
</server>
```

You can also alternatively test the latest release version of FusionDB by setting the system properties for the Docker image: `repo.evolvedbinary.com:9443/evolvedbinary/fusiondb-server:latest`. 

**NOTE:** If you wish to perform the tests against eXist-db as opposed to FusionDB, you need to set the Docker Image, and then the Host and Port
for the API via System Properties of Environment Variables, as by default it is configured for FusionDB.

### Running tests with Docker
Just execute the following:
```
$ mvn clean verify
```

or, if you need to set system properties you can do so like (e.g. for testing against eXist-db 5.2.0):
```
$ mvn clean verify -Dapi.port=8080 -Ddocker.db.image=existdb/existdb:5.2.0
```
