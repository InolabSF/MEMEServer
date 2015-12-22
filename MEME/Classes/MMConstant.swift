/// MARK: - functions

/**
* display log
* @param body log
*/
func MMLOG(body: Any) {
    #if DEBUG
        print(body)
    #endif
}


/// MARK: - MEME
/*
struct MEME {
    static let AppID =          kMEMEAppID
    static let AppSecret =      kMEMEAppSecret
}
*/