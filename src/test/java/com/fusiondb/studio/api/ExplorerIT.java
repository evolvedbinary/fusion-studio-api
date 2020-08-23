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

import org.junit.jupiter.api.Test;

import static com.fusiondb.studio.api.API.getApiBaseUri;
import static io.restassured.RestAssured.when;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static org.apache.http.HttpStatus.*;

public class ExplorerIT {

    @Test
    public void root() {
        when().
                get(getApiBaseUri() + "/explorer?uri=/").
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("explorer-schema.json"));
    }

    @Test
    public void db() {
        when().
                get(getApiBaseUri() + "/explorer?uri=/db").
        then().
                statusCode(SC_OK).
        assertThat().
                body(matchesJsonSchemaInClasspath("explorer-schema.json"));
    }

    @Test
    public void invalidUri() {
        when().
                get(getApiBaseUri() + "/explorer?uri=/invalid").
        then().
                statusCode(SC_BAD_REQUEST);
    }

    /**
     * Attempt to access a non-public Collection as guest user.
     */
    @Test
    public void insufficientPermissions() {
        when().
                get(getApiBaseUri() + "/explorer?uri=/db/system/security").
        then().
                statusCode(SC_FORBIDDEN);
    }
}
