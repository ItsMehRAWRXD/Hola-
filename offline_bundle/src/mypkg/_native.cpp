#include <Python.h>

static PyObject* native_add(PyObject* /*self*/, PyObject* args) {
    long a = 0;
    long b = 0;
    if (!PyArg_ParseTuple(args, "ll", &a, &b)) {
        return nullptr;
    }
    return PyLong_FromLong(a + b);
}

static PyMethodDef NativeMethods[] = {
    {"add", native_add, METH_VARARGS, "Add two integers and return the sum."},
    {nullptr, nullptr, 0, nullptr}
};

static struct PyModuleDef NativeModule = {
    PyModuleDef_HEAD_INIT,
    "_native",
    "Minimal native extension module",
    -1,
    NativeMethods
};

PyMODINIT_FUNC PyInit__native(void) {
    return PyModule_Create(&NativeModule);
}