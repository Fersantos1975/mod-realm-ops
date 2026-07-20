# This hook runs after AzerothCore creates the static/dynamic module targets.
# It exposes the generated build-info header and the active CMake configuration.
set(REALMOPS_GENERATED_INCLUDE_DIR "${CMAKE_BINARY_DIR}/modules/mod-realm-ops")

if(TARGET modules)
    target_include_directories(modules PRIVATE "${REALMOPS_GENERATED_INCLUDE_DIR}")
    target_compile_definitions(modules PRIVATE REALMOPS_BUILD_TYPE="$<CONFIG>")
endif()

if(TARGET mod_mod-realm-ops)
    target_include_directories(mod_mod-realm-ops PRIVATE "${REALMOPS_GENERATED_INCLUDE_DIR}")
    target_compile_definitions(mod_mod-realm-ops PRIVATE REALMOPS_BUILD_TYPE="$<CONFIG>")
endif()
