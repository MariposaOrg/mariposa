package org.mariposa.mariposa

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform