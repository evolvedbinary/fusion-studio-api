xquery version "3.1";

module namespace sec = "http://evolvedbinary.com/ns/pebble/api/security";

import module namespace sm = "http://exist-db.org/xquery/securitymanager";

declare function sec:list-users() as array(xs:string) {
    array { sm:list-users() }
};

declare function sec:list-groups() as array(xs:string) {
    array { sm:list-groups() }
};

declare function sec:get-user($username as xs:string) as map(xs:string, item())? {
    if (sm:list-users() = $username)
    then
        map {
            "userName": $username,
            "enabled": sm:is-account-enabled($username),
            "expired": false(),
            "umask": sm:get-umask($username),
            "metadata": array {
                for $key in sm:get-account-metadata-keys($username)
                return
                    map {
                        "key": $key,
                        "value": sm:get-account-metadata($username, $key)
                    }
            },
            "primaryGroup": sm:get-user-primary-group($username),
            "groups": array { sm:get-user-groups($username) }
        }
    else ()
};

declare function sec:delete-user($username as xs:string) {
    if (sm:list-users() = $username)
    then
        let $_ := sm:remove-account($username)
        return
            true()
    else
        false()
};

declare function sec:get-group($groupname as xs:string) as map(xs:string, item())? {
    if (sm:list-groups() = $groupname)
    then
        map {
            "groupName": $groupname,
            "metadata": array {
                for $key in sm:get-group-metadata-keys($groupname)
                return
                    map {
                        "key": $key,
                        "value": sm:get-group-metadata($groupname, $key)
                    }
            },
            "managers": array { sm:get-group-managers($groupname) }
        }
    else ()
};

declare function sec:delete-group($groupname as xs:string) {
    if (sm:list-groups() = $groupname)
    then
        let $_ := sm:remove-group($groupname)
        return
            true()
    else
        false()
};

