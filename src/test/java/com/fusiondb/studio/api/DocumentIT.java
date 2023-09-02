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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Disabled;


import java.util.Map;

import static com.evolvedbinary.j8fu.tuple.Tuple.Tuple;
import static com.fusiondb.studio.api.API.*;
import static io.restassured.RestAssured.given;
import static io.restassured.RestAssured.when;
import static io.restassured.http.ContentType.JSON;
import static io.restassured.http.ContentType.XML;
import static io.restassured.internal.RestAssuredResponseOptionsGroovyImpl.BINARY;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static java.nio.charset.StandardCharsets.UTF_8;
import static org.apache.http.HttpStatus.*;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.jupiter.api.Assertions.*;

public class DocumentIT {

    @Test
    public void createXml() {
        final String docPath = "/db/fusion-studio-api-test-document-it-1.xml";
        final long now = System.currentTimeMillis();
        final ExtractableResponse<Response> documentResponse = createXml(docPath, "<time>" + now + "</time>");
        assertEquals(docPath, documentResponse.jsonPath().getString("uri"));
        assertFalse(documentResponse.jsonPath().getBoolean("binaryDoc"));
        readDocument(docPath);
    }

    @Disabled("not yet implemented see issue 50")
    @Test
    public void createXmlWithSpaceInName() {
        final String docPath = "/db/fusion-studio-api-test-document-it 2.xml";
        final long now = System.currentTimeMillis();
        final ExtractableResponse<Response> documentResponse = createXml(docPath, "<time>" + now + "</time>");
        assertEquals(docPath, documentResponse.jsonPath().getString("uri"));
        assertFalse(documentResponse.jsonPath().getBoolean("binaryDoc"));
        readDocument(docPath);
    }

    @Disabled("not yet implemented see issue 50")
    @Test
    public void createXmlWithPlusInName() {
        final String docPath = "/db/fusion-studio-api-test-document-it+3.xml";
        final long now = System.currentTimeMillis();
        final ExtractableResponse<Response> documentResponse = createXml(docPath, "<time>" + now + "</time>");
        assertEquals(docPath, documentResponse.jsonPath().getString("uri"));
        assertFalse(documentResponse.jsonPath().getBoolean("binaryDoc"));
        readDocument(docPath);
    }

    @Disabled("not yet implemented see issue 50")
    @Test
    public void createXmlWithUnicodeCharactersInName() {
        final String docPath = "/db/وثيقة-فيوجن-ستوديو.xml-4";
        final long now = System.currentTimeMillis();
        final ExtractableResponse<Response> documentResponse = createXml(docPath, "<time >" + now + "</time>");
        assertEquals(docPath, documentResponse.jsonPath().getString("uri"));
        assertFalse(documentResponse.jsonPath().getBoolean("binaryDoc"));
        readDocument(docPath);
    }

    @Test
    public void createBinary() {
        final String docPath = "/db/fusion-studio-api-test-document-it-2.bin";
        final long now = System.currentTimeMillis();
        final ExtractableResponse<Response> documentResponse = createBinary(docPath, BINARY, Long.toString(now).getBytes(UTF_8));
        assertEquals(docPath, documentResponse.jsonPath().getString("uri"));
        assertTrue(documentResponse.jsonPath().getBoolean("binaryDoc"));
    }

    @Test
    public void deleteDocument() {
        final String documentPath = "/db/fusion-studio-api-test-document-it-col-6";

        // 1. create a document
        final long now = System.currentTimeMillis();
        ExtractableResponse<Response> collectionResponse = createXml(documentPath, "<time>" + now + "</time>");
        assertEquals(documentPath, collectionResponse.jsonPath().getString("uri"));

        // 2. delete the document
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                header(new Header("x-fs-move-source", documentPath)).
        when().
                delete(getApiBaseUri() + "/document?uri=" + documentPath).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. check the document no longer exists
        when().
                get(getApiBaseUri() + "/explorer?uri=" + documentPath).
        then().
                statusCode(SC_FORBIDDEN);  //TODO(AR) should this be SC_NOT_FOUND?
    }

    @Test
    public void updateOwnerAndGroup() {
        final String docPath = "/db/fusion-studio-api-test-document-it-3.xml";

        // 1. create the document
        final long now = System.currentTimeMillis();
        ExtractableResponse<Response> documentResponse = createXml(docPath, "<time>" + now + "</time>");
        assertEquals(docPath, documentResponse.jsonPath().getString("uri"));
        assertFalse(documentResponse.jsonPath().getBoolean("binaryDoc"));
        assertEquals(DEFAULT_ADMIN_USERNAME, documentResponse.jsonPath().getString("owner"));
        assertEquals("dba", documentResponse.jsonPath().getString("group"));

        // 2. update the document owner and group
        final Map<String, Object> requestBody = mapOf(
                Tuple("owner", "guest"),
                Tuple("group", "guest")
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/document?uri=" + docPath).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. get the document properties
        documentResponse = given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
        when().
                get(getApiBaseUri() + "/explorer?uri=" + docPath).
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("document-schema.json")).
        extract();
        assertEquals("guest", documentResponse.jsonPath().getString("owner"));
        assertEquals("guest", documentResponse.jsonPath().getString("group"));
    }

    @Test
    public void updateMode() {
        final String docPath = "/db/fusion-studio-api-test-document-it-4.xml";

        // 1. create the document
        final long now = System.currentTimeMillis();
        ExtractableResponse<Response> documentResponse = createXml(docPath, "<time>" + now + "</time>");
        assertEquals(docPath, documentResponse.jsonPath().getString("uri"));
        assertFalse(documentResponse.jsonPath().getBoolean("binaryDoc"));
        assertEquals("rw-r--r--", documentResponse.jsonPath().getString("mode"));

        // 2. update the document mode
        final Map<String, Object> requestBody = mapOf(
                Tuple("mode", "rwxr-----")
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/document?uri=" + docPath).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. get the document properties
        documentResponse = given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
        when().
                get(getApiBaseUri() + "/explorer?uri=" + docPath).
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("document-schema.json")).
        extract();
        assertEquals("rwxr-----", documentResponse.jsonPath().getString("mode"));
    }

    @Test
    public void updateMediaType() {
        Assumptions.assumeFalse(testServerHasBadXmldbSetMimeType(), "Server has bad XML:DB setMimetype");

        final String docPath = "/db/fusion-studio-api-test-document-it-5.xml";

        // 1. create the document
        final long now = System.currentTimeMillis();
        ExtractableResponse<Response> documentResponse = createXml(docPath, "<time>" + now + "</time>");
        assertEquals(docPath, documentResponse.jsonPath().getString("uri"));
        assertFalse(documentResponse.jsonPath().getBoolean("binaryDoc"));
        assertEquals("application/xml", documentResponse.jsonPath().getString("mediaType"));

        // 2. update the document mediaType
        final Map<String, Object> requestBody = mapOf(
                Tuple("mediaType", "application/xslt+xml")
        );
        given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                contentType(JSON).
                body(requestBody).
        when().
                post(getApiBaseUri() + "/document?uri=" + docPath).
        then().
                statusCode(SC_NO_CONTENT);

        // 3. get the document properties
        documentResponse = given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
        when().
                get(getApiBaseUri() + "/explorer?uri=" + docPath).
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("document-schema.json")).
        extract();
        assertEquals("application/xslt+xml", documentResponse.jsonPath().getString("mediaType"));
    }

    private ExtractableResponse<Response> createBinary(final String path, final String mediaType, final byte[] data) {
        return
            given().
                    auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                    contentType(mediaType).
                    body(data).
            when().
                    put(getApiBaseUri() + "/document?uri=" + path).
            then().
                    statusCode(SC_CREATED).
            assertThat().
                    body(matchesJsonSchemaInClasspath("document-schema.json")).
            extract();
    }

    private ExtractableResponse<Response> createXml(final String path, final String xml) {
        return
            given().
                    auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                    contentType(XML).
                    body(xml).
            when().
                    put(getApiBaseUri() + "/document?uri=" + path).
            then().
                    statusCode(SC_CREATED).
            assertThat().
                    body(matchesJsonSchemaInClasspath("document-schema.json")).
            extract();
    }

    private ExtractableResponse<Response> readDocument(final String path) {
        return
            given().
                auth().preemptive().basic(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD).
                when().
                get(getApiBaseUri() + "/explorer?uri=" + path).
                then().
                statusCode(SC_OK).
                assertThat().
                body(matchesJsonSchemaInClasspath("document-schema.json")).
                body("uri", equalTo(path)).
                extract();
    }
}
