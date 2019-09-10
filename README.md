# Fusion Studio API
[![Build Status](https://travis-ci.com/evolvedbinary/fusion-studio-api.svg?branch=master)](https://travis-ci.com/evolvedbinary/fusion-studio-api)
[![License](https://img.shields.io/badge/license-AGPL%203-blue.svg)](https://opensource.org/licenses/AGPL-3.0)

Server Side API for [Fusion Studio](https://github.com/evolvedbinary/fusion-studio) written in RESTXQ and XQuery.

API documentation is here: https://app.swaggerhub.com/apis/evolvedbinary/pebble-api/1.1.0

## Build Instructions

Requirements:
* Java's [JDK](https://openjdk.java.net/install/) 8+
* [Apache Maven](https://maven.apache.org/) 3.3+

```bash
$ git clone https://github.com/evolvedbinary/fusion-studio-api.git
$ cd fusion-studio-api
$ mvn clean package
```

This will create an EXPath package in `target/fusion-studio-api-x.y.z.xar`, which can be deployed to FusionDB. 
