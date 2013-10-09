static NSString *kActionWaiting = @"Waiting";
static NSString *kActionSubmitWord = @"Submit Word";
static NSString *kActionSubmitAnswer = @"Submit Answer";
static NSString *kActionChoosePhoto = @"Choose Photo";
static NSString *kActionSubmitPhoto = @"Submit Photo";

typedef enum actionTypes {
    
    WAITING = 0,
    SUBMITWORD = 1,
    SUBMITANSWER = 2,
    SUBMITPHOTO = 3,
    CHOOSEPHOTO = 4
    
} Action;

// Parse App ID
static NSString *kParseAppId = @"XMzdxstKDF3DcEu63nyB4F7TSjEO8dt7165emViE";

// Parse Client Key
static NSString *kParseClientKey = @"OLenYplqCxoLjfgBYq5KXtOcvUFcLaElZ1Z6kWCw";

// Parse Cloud Url
//https://api.parse.com/1/functions/setupRoundWords




// Parse Class Key Names
static NSString *kParseClassUser = @"User";
static NSString *kParseClassWord = @"Word";
static NSString *kParseClassGame = @"Game";
static NSString *kParseClassGameUser = @"GameUsers";
static NSString *kParseClassRound = @"Round";
static NSString *kParseClassRoundUser = @"RoundUsers";
static NSString *kParseClassRoundWords = @"RoundWords";
static NSString *kParseClassRoundWordSubmitted = @"RoundWordSubmitted";
