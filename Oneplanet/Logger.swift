//
//  Logger.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import SwiftyBeaver

let logger = SwiftyBeaver.self

func setUpLogger() {
    let console = ConsoleDestination()
    console.format = "$DHH:mm:ss$d $L $M"
    console.useTerminalColors = true
    #if (DEBUG)
    console.minLevel = .verbose
    #else
    console.minLevel = .warning
    #endif
    logger.addDestination(console)
}
