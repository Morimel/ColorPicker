//
//  IKEAColor.swift
//  ColorPicker
//
//  Created by Nikita Nikandrov on 11.10.2025.
//

import Foundation
import SwiftUI

struct IKEAColor: ColorDataProtocol {
    let id: String
    let name: String
    let hex: String
    let rgb: RGB
    let cmyk: CMYK
    
    init(index: Int, name: String, hex: String) {
        self.id = "IKEA \(String(format: "%04d", index + 1))"
        self.name = name
        self.hex = hex
        self.rgb = IKEAColor.hexToRGB(hex)
        self.cmyk = IKEAColor.hexToCMYK(hex)
    }
    
    private static func hexToRGB(_ hex: String) -> RGB {
        var hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexString.hasPrefix("#") {
            hexString = String(hexString.dropFirst())
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        
        let r = Int((rgb & 0xFF0000) >> 16)
        let g = Int((rgb & 0x00FF00) >> 8)
        let b = Int(rgb & 0x0000FF)
        
        return RGB(r: r, g: g, b: b)
    }
    
    private static func hexToCMYK(_ hex: String) -> CMYK {
        let rgb = hexToRGB(hex)
        
        let r = Double(rgb.r) / 255.0
        let g = Double(rgb.g) / 255.0
        let b = Double(rgb.b) / 255.0
        
        let k = 1.0 - max(r, g, b)
        var c, m, y: Double
        
        if k == 1.0 {
            c = 0.0
            m = 0.0
            y = 0.0
        } else {
            c = (1.0 - r - k) / (1.0 - k)
            m = (1.0 - g - k) / (1.0 - k)
            y = (1.0 - b - k) / (1.0 - k)
        }
        
        return CMYK(
            c: Int(c * 100),
            m: Int(m * 100),
            y: Int(y * 100),
            k: Int(k * 100)
        )
    }
}

extension IKEAColor {
    static let ikeaPalette: [IKEAColor] = {
        let names = [
            "IKEA001", "IKEA002", "IKEA003", "IKEA004", "IKEA005",
            "IKEA006", "IKEA007", "IKEA008", "IKEA009", "IKEA010",
            "IKEA011", "IKEA012", "IKEA013", "IKEA014", "IKEA015",
            "IKEA016", "IKEA017", "IKEA018", "IKEA019", "IKEA020",
            "IKEA021", "IKEA022", "IKEA023", "IKEA024", "IKEA025",
            "IKEA026", "IKEA027", "IKEA028", "IKEA029", "IKEA030",
            "IKEA031", "IKEA032", "IKEA033", "IKEA034", "IKEA035",
            "IKEA036", "IKEA037", "IKEA038", "IKEA039", "IKEA040",
            "IKEA041", "IKEA042", "IKEA043", "IKEA044", "IKEA045",
            "IKEA046", "IKEA047", "IKEA048", "IKEA049", "IKEA050",
            "IKEA051", "IKEA052", "IKEA053", "IKEA054", "IKEA055",
            "IKEA056", "IKEA057", "IKEA058", "IKEA059", "IKEA060",
            "IKEA061", "IKEA062", "IKEA063", "IKEA064", "IKEA065",
            "IKEA066", "IKEA067", "IKEA068", "IKEA069", "IKEA070",
            "IKEA071", "IKEA072", "IKEA073", "IKEA074", "IKEA075",
            "IKEA076", "IKEA077", "IKEA078", "IKEA079", "IKEA080",
            "IKEA081", "IKEA082", "IKEA083", "IKEA084", "IKEA085",
            "IKEA086", "IKEA087", "IKEA088", "IKEA089", "IKEA090",
            "IKEA091", "IKEA092", "IKEA093", "IKEA094", "IKEA095",
            "IKEA096", "IKEA097", "IKEA098", "IKEA099", "IKEA100",
            "IKEA101", "IKEA102", "IKEA103", "IKEA104", "IKEA105",
            "IKEA106", "IKEA107", "IKEA108", "IKEA109", "IKEA110",
            "IKEA111", "IKEA112", "IKEA113", "IKEA114", "IKEA115",
            "IKEA116", "IKEA117", "IKEA118", "IKEA119", "IKEA120",
            "IKEA121", "IKEA122", "IKEA123", "IKEA124", "IKEA125",
            "IKEA126", "IKEA127", "IKEA128", "IKEA129", "IKEA130",
            "IKEA131", "IKEA132", "IKEA133", "IKEA134", "IKEA135",
            "IKEA136", "IKEA137", "IKEA138", "IKEA139", "IKEA140",
            "IKEA141", "IKEA142", "IKEA143", "IKEA144", "IKEA145",
            "IKEA146", "IKEA147", "IKEA148", "IKEA149", "IKEA150",
            "IKEA151", "IKEA152", "IKEA153", "IKEA154", "IKEA155",
            "IKEA156", "IKEA157", "IKEA158", "IKEA159", "IKEA160",
            "IKEA161", "IKEA162", "IKEA163", "IKEA164", "IKEA165",
            "IKEA166", "IKEA167", "IKEA168", "IKEA169", "IKEA170",
            "IKEA171", "IKEA172", "IKEA173", "IKEA174", "IKEA175",
            "IKEA176", "IKEA177", "IKEA178", "IKEA179", "IKEA180",
            "IKEA181", "IKEA182", "IKEA183", "IKEA184", "IKEA185",
            "IKEA186", "IKEA187", "IKEA188", "IKEA189", "IKEA190",
            "IKEA191", "IKEA192", "IKEA193", "IKEA194", "IKEA195",
            "IKEA196", "IKEA197", "IKEA198", "IKEA199", "IKEA200"
        ]
        
        let hexValues = [
            "#F8F1E6", "#EFE8E1", "#F9F2EC", "#F7F2EB", "#EDE8E0",
            "#EEE7DD", "#F4F0E5", "#EFE4D3", "#F8F3E9", "#F3ECDE",
            "#F6F3E7", "#EEE7D3", "#F4F2E5", "#EEEADA", "#F8F7E9",
            "#F4F2E9", "#EEF3E7", "#EAEADF", "#EFF5F0", "#ECF4EC",
            "#BEC675", "#F2F1EE", "#E4CBCB", "#F7F0E7", "#CBBEB1",
            "#EBE0D9", "#CC6653", "#E7E1D8", "#816F66", "#F6F0E8",
            "#F7E2DD", "#EDCDC7", "#F4D9CE", "#DCB8A8", "#F8E9D3",
            "#EFCB9B", "#FDE5B0", "#E6CDAA", "#FBEBBD", "#F9DF9C",
            "#F9EFD6", "#D9CCA6", "#EBEFBD", "#B5D1AB", "#BBE1D7",
            "#C3DCC9", "#DDE9ED", "#C2E4EA", "#D2DCEF", "#C6D7E3",
            "#E1E4E6", "#B3C4D5", "#E8DDE2", "#D2CBDD", "#7E8177",
            "#F7F8DF", "#E4E7E3", "#F7E5D3", "#B34C53", "#D2DDDB",
            "#ECEBAF", "#DEDFC3", "#935E7C", "#E7E3E9", "#DFB5B0",
            "#A85953", "#F5C2AC", "#E09673", "#FFD28E", "#F0B67E",
            "#FBE6CE", "#EFCD96", "#FAEE9F", "#FADB89", "#E2E38D",
            "#C7C896", "#D3DFC1", "#9CAD7F", "#BAE0CC", "#96BB9F",
            "#BFDAD7", "#729E9C", "#B6DCE6", "#83AAC1", "#9FC1DF",
            "#748DAC", "#CAB6C9", "#8B859D", "#6A443B", "#CDDCD0",
            "#574C49", "#F3DEA9", "#F4EFE5", "#D6DBB7", "#726965",
            "#CFD9E4", "#006673", "#E5E1BF", "#E2A3B3", "#B8516C",
            "#D6A496", "#7E3738", "#CD746D", "#9A3636", "#C5714F",
            "#864633", "#ECD193", "#D69C54", "#F4D96C", "#F4C472",
            "#F7EE9C", "#D3BD76", "#E0DEA6", "#93AB67", "#C1D0A6",
            "#5E7A65", "#A6CABF", "#317983", "#9BC2D8", "#6C8EA3",
            "#8896B3", "#3A5170", "#C5BEB1", "#FFB953", "#EAE3D3",
            "#C6628C", "#D0D4D8", "#4A72B0", "#F7F3E6", "#9B2C2C",
            "#E3ECDE", "#507A4F", "#C2ADAB", "#856A73", "#DECDC3",
            "#B99F90", "#B4A18F", "#645850", "#EBD9C3", "#A58369",
            "#E4DECC", "#C6B294", "#D9C6AB", "#D9B27D", "#CFC7A2",
            "#847763", "#9D947B", "#676450", "#CCD0BA", "#A7A58F",
            "#CCD7CA", "#494F50", "#B1CBC9", "#667480", "#AAB1B8",
            "#676973", "#B7975E", "#7C9195", "#DDCBCD", "#4D3E45",
            "#EFE6C0", "#7F6F63", "#423A45", "#ABB7B9", "#91D0C5",
            "#D1BAA5", "#D7D2C5", "#9E9893", "#B7AE9D", "#827672",
            "#E0D3BE", "#6C645D", "#D1C9B8", "#AFA08C", "#DFD7C1",
            "#9D978A", "#D7CFBA", "#69645D", "#B6BBAD", "#81857E",
            "#B2BCB8", "#9AA1A0", "#CFD8D2", "#788082", "#7B7B79",
            "#302F2F", "#BEBFB8", "#646462", "#DDDFD3", "#D3D9CD",
            "#DBB651", "#DACBB2", "#BA5B3A", "#9A9E95", "#286A4C",
            "#D3CAB5", "#473633", "#89807A", "#978A65", "#ECE0C9"
        ]
        
        return zip(names, hexValues).enumerated().map { (index, pair) in
            IKEAColor(index: index, name: pair.0, hex: pair.1)
        }
    }()
}
