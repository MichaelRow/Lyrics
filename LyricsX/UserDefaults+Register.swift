//
//  UserDefaults+Register.swift
//  LyricsX
//
//  Created by Eru on 2017/8/26.
//  Copyright © 2017年 Eru. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    func setRegister() {

        let defaults = [ GeneralSetting.qianqianServer.identifier : 0,
                         LyricSetting.downloadTranslation.identifier : true,
                         LyricSetting.downloadWordBase.identifier : true ]
            as [String : Any]
        
        register(defaults: defaults)
        
    }
}
