#define EXNPrefsIdentifier @"io.securarepo.exonotch"
#define EXNNotification @"io.securarepo.exonotch/ReloadPrefs"
#define EXNRefreshNotification @"io.securarepo.exonotch/Refresh"
#define EXNThemesDirectory @"/Library/ExoNotch/"

@interface EXNTheme : NSObject {
  UIImage *_previewImage;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, retain) NSDictionary *info;

+ (EXNTheme *)themeWithDirectoryName:(NSString *)name;
+ (EXNTheme *)themeWithPath:(NSString *)path;
- (NSString *)getPath:(NSString *)filename;
- (id)initWithPath:(NSString *)path;
- (UIImage *)getImage:(NSString *)filename;
- (UIImage *)getPreviewImage:(BOOL)modern;

@end