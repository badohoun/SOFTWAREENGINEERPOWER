from packaging_demo.states_info import is_city_capitol_of_state

def test__is_city_capitol_of_state___for_correct_city_state_pair():
    assert is_city_capitol_of_state(city_name="Montgomery",state="Alabama")

def test__is_city_capitol_of_state___false_for_incorrect_city_state_pair():
    assert  not is_city_capitol_of_state(city_name="Salt Lake City",state="Alabama")