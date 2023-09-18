////////////////////////////////////////////////////////////
//
// SFML - Simple and Fast Multimedia Library
// Copyright (C) 2007-2023 Laurent Gomila (laurent@sfml-dev.org)
//
// This software is provided 'as-is', without any express or implied warranty.
// In no event will the authors be held liable for any damages arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it freely,
// subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented;
//    you must not claim that you wrote the original software.
//    If you use this software in a product, an acknowledgment
//    in the product documentation would be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such,
//    and must not be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source distribution.
//
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// Headers
////////////////////////////////////////////////////////////
#include <SFML/System/Thread.h>
#include <SFML/System/ThreadStruct.h>
#include <SFML/Internal.h>


////////////////////////////////////////////////////////////
sfThread* sfThread_create(void (*function)(void*), void* userData)
{
    return new sfThread(function, userData);
}


////////////////////////////////////////////////////////////
void sfThread_destroy(sfThread* thread)
{
    delete thread;
}


////////////////////////////////////////////////////////////
void sfThread_launch(sfThread* thread)
{
    CSFML_CALL(thread, launch());
}


////////////////////////////////////////////////////////////
void sfThread_wait(sfThread* thread)
{
    CSFML_CALL(thread, wait());
}


////////////////////////////////////////////////////////////
void sfThread_terminate(sfThread* thread)
{
    CSFML_CALL(thread, terminate());
}
