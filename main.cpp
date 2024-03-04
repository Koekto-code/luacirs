#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>
#include <glad/gl.h>

#include <lua.hpp>

#include <iostream>

constexpr int qwihbviuww = 200;

static void keyCallback(GLFWwindow *window, int key, int scancode, int action, int mods)
{
	if (action != GLFW_RELEASE)
	{
		if (key == GLFW_KEY_ESCAPE) {
			if (glfwGetInputMode(window, GLFW_CURSOR) == GLFW_CURSOR_DISABLED)
				glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
		}

		int cmov = 0;
	}
}

static void resizeCallback(GLFWwindow *window, int w, int h)
{
	glViewport(0, 0, w, h);
}

static int report_err(lua_State *L) {
	fprintf(stderr, "Lua error stack traceback:\n%s\n", lua_tostring(L, -1));
	lua_pop(L, 1);
	lua_close(L);
	return 1;
}

typedef struct
{
	float xb;
	float yb;
	float xe;
	float ye;
}
Line;

typedef struct
{
	float x;
	float y;
}
vec2;

int main()
{
	if (!glfwInit()) {
		std::cout << "glfw init failed\n";
		return 1;
	}

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_COMPAT_PROFILE);
	GLFWwindow *wnd = glfwCreateWindow(800, 600, "circuit simulator", NULL, NULL);

	if (wnd == NULL) {
		std::cout << "wnd isn't created\n";
		return 1;
	}

	glfwMakeContextCurrent(wnd);
	auto loadfn = reinterpret_cast<GLADloadfunc>(glfwGetProcAddress);
	if (!gladLoadGL(loadfn)) {
		std::cout << "GLAD not loaded\n";
		return -1;
	}

	// =======================================

	const char *luamain = "main.lua";

	lua_State* L = luaL_newstate();
	luaopen_base(L);
	luaL_openlibs(L);
	lua_settop(L, 0);

	int retcode = luaL_dofile(L, luamain);
	if (retcode) {
		std::cerr << "Failed to execute " << luamain << '\n';
		return report_err(L);
	}

	lua_getglobal(L, "circuit");
	if (!lua_istable(L, 1)) {
		std::cerr << "'circuit' isn't existing global table\n";
		lua_close(L);
		return 1;
	}

	lua_getglobal(L, "checkVoltage");
	if (!lua_isfunction(L, 2)) {
		std::cerr << "'checkVoltage' isn't existing global function\n";
		lua_close(L);
		return 1;
	}

	lua_getglobal(L, "runLoop");
	if (!lua_isfunction(L, 2)) {
		std::cerr << "'runLoop' isn't existing global function\n";
		lua_close(L);
		return 1;
	}

	// =======================================

	glfwSetKeyCallback(wnd, keyCallback);
	glfwSetFramebufferSizeCallback(wnd, resizeCallback);
	glfwSwapInterval(1);

	int iteration = 0;
	vec2 points[qwihbviuww];
	for (auto &p: points) p = {0, 0};

	glClearColor(0.f, 0.f, 0.f, 1.f);

	while (!glfwWindowShouldClose(wnd))
	{
		glfwPollEvents();

		lua_settop(L, 3);
		lua_pushvalue(L, 3);
		if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
			std::cerr << "error here1\n";
			return report_err(L);
		}
		lua_pushvalue(L, 2);
		if (lua_pcall(L, 0, 1, 0) != LUA_OK) {
			std::cerr << "error here\n";
			return report_err(L);
		}

		float v1 = lua_tonumber(L, -1);
		float x1 = float(iteration) * (2.f / (qwihbviuww - 1)) - 1.f;

		points[iteration++] = {x1, v1};

		glColor4f(0.f, 1.f, 0.f, 0.f);
		glClear(GL_COLOR_BUFFER_BIT);

		glBegin(GL_LINES);
		for (int i = 1; i != iteration; ++i) {
			glVertex2f(points[i - 1].x, points[i - 1].y);
			glVertex2f(points[i].x, points[i].y);
		}
		glEnd();

		if (iteration == qwihbviuww) {
			iteration = 0;
		}
		glfwSwapBuffers(wnd);
	}

	glfwTerminate();
}
