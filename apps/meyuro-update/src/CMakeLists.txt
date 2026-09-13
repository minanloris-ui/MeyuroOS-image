# SPDX-License-Identifier: GPL-3.0-or-later

kcmutils_add_qml_kcm(kcm_meyuro_update)

target_sources(kcm_meyuro_update PRIVATE
    meyuroupdatemodule.cpp
    meyuroupdatemodule.h
)

target_link_libraries(kcm_meyuro_update PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Qml
    KF6::CoreAddons
    KF6::I18n
    KF6::KCMUtils
    KF6::KCMUtilsQuick
)
