static NSString *kActionWaiting = @"Refresh";
static NSString *kActionSubmitWord = @"Submit Word";
static NSString *kActionSubmitAnswer = @"Submit Answer";
static NSString *kActionChoosePhoto = @"Choose Photo";
static NSString *kActionSubmitPhoto = @"Submit Photo";

static NSString *kPostNoteGetStatus = @"GetGameStatus";

typedef enum actionTypes {
    
    WAITING = 0,
    SUBMITWORD = 1,
    SUBMITANSWER = 2,
    SUBMITPHOTO = 3,
    CHOOSEPHOTO = 4
    
} Action;

// PARSE PRODUCTION APP STRINGS
// Parse App ID - PicsWithFriends
static NSString *kParseAppId = @"XMzdxstKDF3DcEu63nyB4F7TSjEO8dt7165emViE";
// Parse Client Key - PicsWithFriends
static NSString *kParseClientKey = @"OLenYplqCxoLjfgBYq5KXtOcvUFcLaElZ1Z6kWCw";


// PARSE DEVELOPMENT APP STRINGS
// Parse App ID - PicsWithFriends
static NSString *kParseAppIdDev = @"tdPmnifytqM7SIkV49t5dxnY5PwVR5qBSKdqoDzB";
// Parse Client Key - PicsWithFriends
static NSString *kParseClientKeyDev = @"aNifhkJgq1sxKXJwdfXYJkjjWkWaSChvayNyLTwZ";



// Parse Cloud Url Example
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

static NSString *kFacebookGraph = @"http://graph.facebook.com";
static NSString *kFacebookGraphPictureSize100x100 = @"height=100&width=100";
