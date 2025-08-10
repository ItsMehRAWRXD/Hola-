import mypkg


def test_add():
    assert mypkg.add(2, 3) == 5


if __name__ == "__main__":
    test_add()
    print("ok")