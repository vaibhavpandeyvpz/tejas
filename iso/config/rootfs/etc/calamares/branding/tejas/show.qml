/*
 * No images, no external assets.
 */

import QtQuick 2.0
import calamares.slideshow 1.0

Presentation
{
    id: presentation

    Timer {
        id: advanceTimer
        interval: 6000
        running: false
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        centeredText: "Welcome to Tejas Linux\n\nA lightweight, secure, Ubuntu-based operating system."
    }

    Slide {
        centeredText: "Designed for clarity and control\n\nTejas Linux uses a modern, transparent build system\nand avoids legacy tooling."
    }

    Slide {
        centeredText: "Secure by default\n\nUEFI Secure Boot is enabled using\nMicrosoft and Canonical signed components."
    }

    Slide {
        centeredText: "Simple installation\n\nThe installer will guide you through disk setup,\nusers, and system configuration."
    }

    Slide {
        centeredText: "Ready when you are\n\nThank you for choosing Tejas Linux."
    }

    Component.onCompleted: advanceTimer.running = true
}
