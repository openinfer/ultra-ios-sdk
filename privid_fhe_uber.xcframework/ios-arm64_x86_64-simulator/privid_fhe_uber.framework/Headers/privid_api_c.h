/** @file 
 *
 * This cpp file is the api header file exposing APIs for FACE
 * to perform :
 *         Uber Lightweight Librarz
 * @par
 * COPYRIGHT NOTICE: (c) 2024 Private Identity.  All rights reserved.
 */

#ifndef PRIVID_UBER_LIB_H_
#define PRIVID_UBER_LIB_H_

#ifdef __EMSCRIPTEN__
    #include <emscripten.h>
#endif // #ifdef __EMSCRIPTEN__

#ifdef __EMSCRIPTEN__
    #define PRIVID_API_ATTRIB EMSCRIPTEN_KEEPALIVE
#else // #ifdef __EMSCRIPTEN__
    #if (defined(__linux__) || defined(__CYGWIN__) || defined(__clang__))
        #define PRIVID_API_ATTRIB __attribute__((visibility("default")))
    #else
        #define PRIVID_API_ATTRIB __declspec(dllexport)
    #endif // (defined(__linux__) || defined(__CYGWIN__))
#endif // #ifdef __EMSCRIPTEN__

#ifdef __cplusplus
    #include <cstdint>
    extern "C" {
#else
    typedef unsigned char uint8_t;
    #include <stdbool.h>
    #include <stdint.h>
#endif // #ifdef __cplusplus
    
/**
* Initializes the library with the working directory. It should be called only once before the first #privid_initialize_session call.
*
* \param[in]    working_directory          The full UTF-8 encoded path for the working directory with Atlas DB files and read/write access.
* \param[in]    working_directory_length   The size of the #working_directory string in bytes.
*/
PRIVID_API_ATTRIB void privid_initialize_lib(
    const char* working_directory, const int working_directory_length);

/**
* Creates a new session and returns a pointer to it. After usage, the session must be cleared by calling #privid_deinitialize_session.
*
* \param[in]    settings            The UTF-8 encodded JSON string with session configuration parameters.
* \param[in]    settings_length     The size of the #settings string in bytes.
* \param[out]   session_ptr         The initialized session pointer.
*
* \return       True for successful initialization false otherwise.
*/
PRIVID_API_ATTRIB bool privid_initialize_session(
    const char* settings, const unsigned int settings_length, void** session_ptr);

/**
* De-initializes the session, which was already initialized using #privid_initialize_session call.
*
* \param[in]    session_ptr     The session pointer which obtained from the function #privid_initialized_session call.
*/
PRIVID_API_ATTRIB void privid_deinitialize_session(void* session_ptr);

/**
* Frees the memory allocated for output buffer by other functions in API.
*
* \param[in]    buffer      The buffer pointer allocated by API before.
*/
PRIVID_API_ATTRIB void privid_free_char_buffer(char* buffer);

/**
* Configures common session parameters by resetting default values for all future function calls.
*
* \param[in]    session_ptr             The session pointer which obtained from the function #privid_initialized_session call.
* \param[in]    user_config             The UTF-8 encodded JSON string with common configuration parameters.
* \param[in]    user_config_length      The size of the #user_config string in bytes.
*/
PRIVID_API_ATTRIB bool privid_set_configuration(
    void* session_ptr, const char* user_config, const int user_config_length);

/**
* Detects and validates face on the input image; if the face is valid, try to add the user to the local database.
* The result is returned in the JSON format for future parsing. In case of success, it contains the user UUID for future usage.
* The input image format (RGB/BGR/RGBA) is controlled by the #user_config value or the previous #privid_set_configuration call.
* After usage, the pointer returned in the #resul_out parameter should be deallocated using the #privid_free_char_buffer call.
*
* \param[in]    session_ptr             The session pointer which obtained from the function #privid_initialized_session call.
* \param[in]    user_config             The UTF-8 encoded JSON string with configuration parameters applied for this operation only.
* \param[in]    user_config_length      The size of the #user_config string in bytes.
* \param[in]    image_bytes             The input image is a raw bytes pixel buffer (bitmap).
* \param[in]    image_width             The pixel width of the #image_bytes input image.
* \param[in]    image_height            The pixel height of the #image_bytes input image.
* \param[out]   result_out              The output buffer for the UTF-8 encoded JSON string with operation results.
* \param[out]   result_out_length       The size of the #result_out string in bytes.
*
* \return       Operation identifier in case of successful completion or negative value in case of errors.
*/
PRIVID_API_ATTRIB int32_t privid_user_enroll(
    void* session_ptr, const char* user_config, const int user_config_length,
    const uint8_t* image_bytes, const int image_width, const int image_height,
    char** result_out, int* result_out_length);

/**
* Detects and validates face on the input image; if the face is valid, try to find the user in the local database.
* The result is returned in the JSON format for future parsing. In case of success, it contains the user UUID for future usage.
* The input image format (RGB/BGR/RGBA) is controlled by the #user_config value or the previous #privid_set_configuration call.
* After usage, the pointer returned in the #resul_out parameter should be deallocated using the #privid_free_char_buffer call.
*
* \param[in]    session_ptr             The session pointer which obtained from the function #privid_initialized_session call.
* \param[in]    user_config             The UTF-8 encoded JSON string with configuration parameters applied for this operation only.
* \param[in]    user_config_length      The size of the #user_config string in bytes.
* \param[in]    image_bytes             The input image is a raw bytes pixel buffer (bitmap).
* \param[in]    image_width             The pixel width of the #image_bytes input image.
* \param[in]    image_height            The pixel height of the #image_bytes input image.
* \param[out]   result_out              The output buffer for the UTF-8 encoded JSON string with operation results.
* \param[out]   result_out_length       The size of the #result_out string in bytes.
*
* \return       Operation identifier in case of successful completion or negative value in case of errors.
*/
PRIVID_API_ATTRIB int32_t privid_user_predict(
    void* session_ptr, const char* user_config, const int user_config_length,
    const uint8_t* image_bytes, const int image_width, const int image_height,
    char** result_out, int* result_out_length);

/**
* Compares two encryped embedding strings and calculates similarity score based on distance between two embeddings.
* After usage, the pointer returned in the #resul_out parameter should be deallocated using the #privid_free_char_buffer call.
*
* \param[in]    session_ptr             The session pointer which obtained from the function #privid_initialized_session call.
* \param[in]    user_config             The UTF-8 encoded JSON string with configuration parameters applied for this operation only.
* \param[in]    user_config_length      The size of the #user_config string in bytes.
* \param[in]    embedding_one           The UTF-8 encoded encrypted embedding previously obtained from the enroll or predict call.
* \param[in]    embedding_one_length    The size of the #embedding_one string in bytes.
* \param[in]    embedding_two           The UTF-8 encoded encrypted embedding previously obtained from the enroll or predict call.
* \param[in]    embedding_two_length    The size of the #embedding_one string in bytes.
* \param[in]    image_height            The pixel height of the #image_bytes input image.
* \param[out]   result_out              The output buffer for the UTF-8 encoded JSON string with operation results.
* \param[out]   result_out_length       The size of the #result_out string in bytes.
*
* \return       Operation identifier in case of successful completion or negative value in case of errors.
*/
PRIVID_API_ATTRIB int32_t privid_compare_embeddings(
    void* session_ptr, const char* user_config, const int user_config_length,
    const char *embedding_one, const int embedding_one_length,
    const char *embedding_two, const int embedding_two_length,
    char** result_out, int* result_out_length);

/**
* Checks if all needed models are loaded properly and initialized correctly.
*
*/
PRIVID_API_ATTRIB bool privid_check_models();

/**
* Gets the library version string for debugging/information purposes.
*
* \return       Static UTF8-encoded string - you don't need to free the returned memory.
*/
PRIVID_API_ATTRIB const char* privid_get_version(void);

/**
* Gets the current models' configuration information for the library. 
* After usage, the pointer returned in the #about_models parameter should be deallocated using the #privid_free_char_buffer call.
*
* \param[in]    session_ptr             The session pointer which obtained from the function #privid_initialized_session call.
* \param[out]   about_models            The UTF-8 encodded JSON string with models' configuration information.
* \param[out]   about_models_length     The size of the #about_models string in bytes.
*/
PRIVID_API_ATTRIB void privid_about_models(
    void* session_ptr, char** about_models, int* about_models_length);

#ifdef __cplusplus
    }
#endif

#endif // PRIVID_UBER_LIB_H_
