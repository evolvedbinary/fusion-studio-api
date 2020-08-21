/*
 * Fusion Studio API - API for Fusion Studio
 * Copyright © 2017 Evolved Binary (tech@evolvedbinary.com)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.fusiondb.studio.api;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static com.evolvedbinary.j8fu.tuple.Tuple.Tuple;
import static com.fusiondb.studio.api.API.*;
import static io.restassured.RestAssured.given;
import static io.restassured.http.ContentType.BINARY;
import static io.restassured.http.ContentType.JSON;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static java.nio.charset.StandardCharsets.UTF_8;
import static org.apache.http.HttpStatus.*;

public class QueryIT {

    /**
     * Store any resources needed for the tests.
     */
    @BeforeAll
    public static void setup() {
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(BINARY).
                body("current-dateTime()".getBytes(UTF_8)).
        when().
                put(getRestApiBaseUri() + "/db/fusion-studio-api-test-query-it/basic-store.xq").
        then().
                statusCode(SC_CREATED);


        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(BINARY).
                body("total-junk()".getBytes(UTF_8)).
        when().
                put(getRestApiBaseUri() + "/db/fusion-studio-api-test-query-it/invalid.xq").
        then().
                statusCode(SC_CREATED);
    }

    @Test
    public void basicExpressionDirectQuery() {
        final Map<String, Object> requestBody = mapOf(
                Tuple("query", "current-dateTime()")
        );

        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/query").
        then().
                statusCode(SC_OK);
    }

    @Test
    public void basicExpressionStoredQuery() {
        final Map<String, Object> requestBody = mapOf(
                Tuple("query-uri", "/db/fusion-studio-api-test-query-it/basic-store.xq")
        );

        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/query").
        then().
                statusCode(SC_OK);
    }

    @Test
    public void basicExpressionNonExistentStoredQuery() {
        final Map<String, Object> requestBody = mapOf(
                Tuple("query-uri", "/db/no-such-query.xq")
        );

        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/query").
        then().
                statusCode(SC_BAD_REQUEST).
        assertThat().
                body(matchesJsonSchemaInClasspath("query-error-schema.json"));
    }

    /**
     * Attempt to run a posted query as guest user.
     */
    @Test
    public void insufficientPermissionsDirectQuery() {
        final Map<String, Object> requestBody = mapOf(
                Tuple("query", "current-dateTime()"),
                Tuple("defaultSerialization", mapOf(
                        Tuple("output", "xml")
                ))
        );

        given().
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/query").
        then().
                statusCode(SC_FORBIDDEN);
    }

    /**
     * Attempt to run a stored query as guest user.
     */
    @Test
    public void insufficientPermissionsStoredQuery() {
        final Map<String, Object> requestBody = mapOf(
                Tuple("query-uri", "/db/some-query.xq"),
                Tuple("defaultSerialization", mapOf(
                        Tuple("output", "xml")
                ))
        );

        given().
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/query").
        then().
                statusCode(SC_FORBIDDEN);
    }

    @Test
    public void invalidDirectQuery() {
        final Map<String, Object> requestBody = mapOf(
                Tuple("query", "total-junk()")
        );

        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/query").
        then().
                statusCode(SC_BAD_REQUEST).
        assertThat().
                body(matchesJsonSchemaInClasspath("query-error-schema.json"));
    }

    @Test
    public void invalidStoredQuery() {
        final Map<String, Object> requestBody = mapOf(
                Tuple("query-uri", "/db/fusion-studio-api-test-query-it/invalid.xq")
        );

        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/query").
        then().
                statusCode(SC_BAD_REQUEST).
        assertThat().
                body(matchesJsonSchemaInClasspath("query-error-schema.json"));
    }
}
