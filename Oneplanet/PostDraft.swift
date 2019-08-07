//
//  PostDraft.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/7.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class PostDraft {
    let isValued: Bool
    var images: [ImageAttachment] = []
    var caption: String = ""
    var captionValidator = InputLengthValidator(max: 200)
    
    init(isValued: Bool) {
        self.isValued = isValued
    }
}
