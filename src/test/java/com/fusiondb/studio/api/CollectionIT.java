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

import io.restassured.http.Header;
import io.restassured.response.ExtractableResponse;
import io.restassured.response.Response;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static com.evolvedbinary.j8fu.tuple.Tuple.Tuple;
import static com.fusiondb.studio.api.API.*;
import static io.restassured.RestAssured.given;
import static io.restassured.RestAssured.when;
import static io.restassured.http.ContentType.JSON;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static org.apache.http.HttpStatus.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.hamcrest.core.IsEqual.equalTo;

public class CollectionIT {

    @Test
    public void createCollection() {
        final String colPath = "/db/fusion-studio-api-test-document-it-col-1";
        final ExtractableResponse<Response> collectionResponse = createCollection(colPath);
        assertEquals(colPath, collectionResponse.jsonPath().getString("uri"));
        readCollection(colPath);
    }

    @Disabled("not yet implemented see issue 50")
    @Test
    public void createCollectionWithSpaceInName() {
        final String colPath = "/db/fusion-studio-api-test-document-it-col 2";
        final ExtractableResponse<Response> collectionResponse = createCollection(colPath);
        assertEquals(colPath, collectionResponse.jsonPath().getString("uri"));
        readCollection(colPath);
    }
    
    @Disabled("not yet implemented see issue 50")
    @Test
    public void createCollectionWithPlusInName() {
        final String colPath = "/db/fusion-studio-api-test-document-it-col+3";
        final ExtractableResponse<Response> collectionResponse = createCollection(colPath);
        assertEquals(colPath, collectionResponse.jsonPath().getString("uri"));
        readCollection(colPath);
    }

    @Disabled("not yet implemented see issue 50")
    @Test
    public void createCollectionWithUnicodeCharactersInName() {
        final String colPath = "/db/مجموعة-فيوجن-ستوديو";
        final ExtractableResponse<Response> collectionResponse = createCollection(colPath);
        assertEquals(colPath, collectionResponse.jsonPath().getString("uri"));
        readCollection(colPath);
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

    @Test
    public void copyCollection() {
        Assumptions.assumeFalse(testServerHasBadCopyMoveCollectionOperations(), "Server has bad copy/move operations");

        final String collectionPath = "/db/fusion-studio-api-test-document-it-col-4";

        // 1. create the source collection
        ExtractableResponse<Response> collectionResponse = createCollection(collectionPath);
        assertEquals(collectionPath, collectionResponse.jsonPath().getString("uri"));

        // 2. copy the source collection
        final String destCollectionPath = "/db/fusion-studio-api-test-document-it-col-4-copy";
        collectionResponse = given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                header(new Header("x-fs-copy-source", collectionPath)).
        when().
                put(getApiBaseUri() + "/collection?uri=" + destCollectionPath).
        then().
                statusCode(SC_CREATED).
        assertThat().
                header("Content-Location", equalTo(destCollectionPath)).
                body(matchesJsonSchemaInClasspath("collection-schema.json")).
        extract();
        assertEquals(destCollectionPath, collectionResponse.jsonPath().getString("uri"));

        // 3. check the source collection still exists
        when().
                get(getApiBaseUri() + "/explorer?uri=" + collectionPath).
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("collection-schema.json"));

        // 4. check the destination collection, i.e. the copy, exists
        when().
                get(getApiBaseUri() + "/explorer?uri=" + destCollectionPath).
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("collection-schema.json"));
    }

    @Test
    public void moveCollection() {
        Assumptions.assumeFalse(testServerHasBadCopyMoveCollectionOperations(),"Server has bad copy/move operations");

        final String collectionPath = "/db/fusion-studio-api-test-document-it-col-5";

        // 1. create the source collection
        ExtractableResponse<Response> collectionResponse = createCollection(collectionPath);
        assertEquals(collectionPath, collectionResponse.jsonPath().getString("uri"));

        // 2. move the source collection
        final String destCollectionPath = "/db/fusion-studio-api-test-document-it-col-5-moved";
        collectionResponse = given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                header(new Header("x-fs-move-source", collectionPath)).
        when().
                put(getApiBaseUri() + "/collection?uri=" + destCollectionPath).
        then().
                statusCode(SC_CREATED).
        assertThat().
                header("Content-Location", equalTo(destCollectionPath)).
                body(matchesJsonSchemaInClasspath("collection-schema.json")).
        extract();
        assertEquals(destCollectionPath, collectionResponse.jsonPath().getString("uri"));

        // 3. check the source collection no longer exists
        when().
                get(getApiBaseUri() + "/explorer?uri=" + collectionPath).
        then().
                statusCode(SC_FORBIDDEN);  //TODO(AR) should this be SC_NOT_FOUND?

        // 4. check the destination collection, i.e. the moved collection, exists
        when().
                get(getApiBaseUri() + "/explorer?uri=" + destCollectionPath).
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("collection-schema.json"));
    }

    @Test
    public void deleteCollection() {
        final String collectionPath = "/db/fusion-studio-api-test-document-it-col-6";

        // 1. create a collection
        ExtractableResponse<Response> collectionResponse = createCollection(collectionPath);
        assertEquals(collectionPath, collectionResponse.jsonPath().getString("uri"));

        // 2. delete the collection
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                header(new Header("x-fs-move-source", collectionPath)).
        when().
                delete(getApiBaseUri() + "/collection?uri=" + collectionPath).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. check the collection no longer exists
        when().
                get(getApiBaseUri() + "/explorer?uri=" + collectionPath).
        then().
                statusCode(SC_FORBIDDEN);  //TODO(AR) should this be SC_NOT_FOUND?
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

    private ExtractableResponse<Response> readCollection(final String path) {
        return
                given().
                        auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                        when().
                        get(getApiBaseUri() + "/explorer?uri=" + path).
                        then().
                        statusCode(SC_OK).
                        assertThat().
                        body(matchesJsonSchemaInClasspath("collection-schema.json")).
                        body("uri", equalTo(path)).
                        extract();
    }
}
