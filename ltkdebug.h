#ifdef LTK_DEBUG
#define ltkdebug(...) g_debug(__VA_ARGS__)
#else
#define ltkdebug(...)  
#endif
