#include <cstdlib>

extern "C" void DimasPrintf(const char* format_string, ...);

int main()
{
    char a = 'a';
    char b = 33;
    char c = 'c';
    char d = 'd';
    char e = 'e';
    int f = -1343;
    int m = 444;

    char str[] = "ussaddsadsdal";
    DimasPrintf("R%d %x %x %x %s\n", f, m, m, m, str);

    system("pause");

    return 0;
}
