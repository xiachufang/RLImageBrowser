//
//  RLConstants.h
//  RLImageBrowser
//
//  Created by kinarobin on 2019/1/31.
//  Copyright © 2019 kinarobin@outlook.com. All rights reserved.
//


#define PAGE_INDEX_TAG_OFFSET   1000
#define PAGE_INDEX(page)        ([(page) tag] - PAGE_INDEX_TAG_OFFSET)

// Debug Logging
#if DEBUG // Set to 1 to enable debug logging
  #define RLLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
  #define RLLog(x, ...)
#endif

