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

import io.restassured.response.ExtractableResponse;
import io.restassured.response.Response;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static com.evolvedbinary.j8fu.tuple.Tuple.Tuple;
import static com.fusiondb.studio.api.API.*;
import static io.restassured.RestAssured.given;
import static io.restassured.http.ContentType.JSON;
import static io.restassured.http.ContentType.XML;
import static io.restassured.internal.RestAssuredResponseOptionsGroovyImpl.BINARY;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static java.nio.charset.StandardCharsets.UTF_8;
import static org.apache.http.HttpStatus.*;
import static org.junit.jupiter.api.Assertions.*;

public class CollectionIT {

    @Test
    public void createCollection() {
        final String colPath = "/db/fusion-studio-api-test-document-it-col-1";
        final ExtractableResponse<Response> collectionResponse = createCollection(colPath);
        assertEquals(colPath, collectionResponse.jsonPath().getString("uri"));
    }

    @Test
    public void updateOwnerAndGroup() {
        final String collectionPath = "/db/fusion-studio-api-test-document-it-col-2";

        // 1. create the collection
        ExtractableResponse<Response> collectionResponse = createCollection(collectionPath);
        assertEquals(collectionPath, collectionResponse.jsonPath().getString("uri"));
        assertEquals(DEFAULT_ADMIN_USERNAME, collectionResponse.jsonPath().getString("owner"));
        assertEquals("dba", collectionResponse.jsonPath().getString("group"));

        // 2. update the collection owner and group
        final Map<String, Object> requestBody = mapOf(
                Tuple("owner", "guest"),
                Tuple("group", "guest")
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/collection?uri=" + collectionPath).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. get the collection properties
        collectionResponse = given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
        when().
                get(getApiBaseUri() + "/explorer?uri=" + collectionPath).
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("collection-schema.json")).
        extract();
        assertEquals("guest", collectionResponse.jsonPath().getString("owner"));
        assertEquals("guest", collectionResponse.jsonPath().getString("group"));
    }

    @Test
    public void updateMode() {
        final String collectionPath = "/db/fusion-studio-api-test-document-it-col-3";

        // 1. create the collection
        ExtractableResponse<Response> collectionResponse = createCollection(collectionPath);
        assertEquals(collectionPath, collectionResponse.jsonPath().getString("uri"));
        assertEquals("rwxr-xr-x", collectionResponse.jsonPath().getString("mode"));

        // 2. update the collection mode
        final Map<String, Object> requestBody = mapOf(
                Tuple("mode", "rwxr-----")
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/collection?uri=" + collectionPath).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. get the collection properties
        collectionResponse = given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
        when().
                get(getApiBaseUri() + "/explorer?uri=" + collectionPath).
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("collection-schema.json")).
        extract();
        assertEquals("rwxr-----", collectionResponse.jsonPath().getString("mode"));
    }

    private ExtractableResponse<Response> createCollection(final String path) {
        return
            given().
                    auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
            when().
                    put(getApiBaseUri() + "/collection?uri=" + path).
            then().
                    statusCode(SC_CREATED).
            assertThat().
                    body(matchesJsonSchemaInClasspath("collection-schema.json")).
            extract();
    }
}
