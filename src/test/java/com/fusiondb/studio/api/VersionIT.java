package com.fusiondb.studio.api;

import org.junit.jupiter.api.Test;

import static com.fusiondb.studio.api.API.getApiBaseUri;
import static io.restassured.RestAssured.when;

public class VersionIT {

    @Test
    public void getServerVersion() {
        when().
                get(getApiBaseUri() + "/version").
        then()
                .statusCode(200);
    }
}
