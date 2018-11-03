# Pebble API
Server Side API for [Pebble](https://github.com/evolvedbinary/pebble) written in RESTXQ and XQuery.

## Build Instructions

Requirements:
* Java's [JDK](https://openjdk.java.net/install/) 8+
* [Apache Maven](https://maven.apache.org/) 3.3+

```bash
$ git clone https://github.com/evolvedbinary/pebble-api.git
$ cd pebble-api
$ mvn clean package
```

This will create an EXPath package in `target/pebble-api-x.y.z.xar`, which can be deployed to Granite. 