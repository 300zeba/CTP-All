import os
import sys
from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys


submission_dir = 'images'

dir_list = list(os.listdir(submission_dir))

file_tup = list();
for directory in dir_list:
    file_list = list(os.listdir(os.path.join(submission_dir,directory)))
    if len(file_list) != 0:
        for i in range(len(file_list)):
            file_tup.append([directory,file_list[i]])

file_tup.sort()

for index in range(len(file_tup)):
    print(file_tup[index][1])

#Web

driver = webdriver.Chrome()

driver.get('http://twonet.cs.uh.edu/webentry/login.html')

#Login
id_box = driver.find_element_by_name('username')
pass_box = driver.find_element_by_name('password')
login_button = driver.find_element_by_class_name('button')

id_box.send_keys('user')
pass_box.send_keys('pasword')
login_button.click()

#Grande Loop de envio

for index in range(len(file_tup)):
    '''
    name = file_tup[index][1].split(".")
    number = file_tup[index][0].split("-")
    number2 = number[1].split("N")
    num_hops = number2[0]
    image_name = num_hops +'-'+name[0]
    number = file_tup[index][1].split("-")
    number2 = number[0].split("t")
    if number2[2][0] == "N":
        number3 = number2[2].split("N")
        num_nodes = int(float(number3[1]))
    else:
        num_nodes = int(float(number2[2]))

    #print(num_nodes)
    '''
    name = file_tup[index][1].split(".")
    image_name = name[0]
    number = sys.argv[1]

    print(number)
    num_nodes = int(float(number))

    print(image_name)



    #Upload Imagem
    driver.get('http://twonet.cs.uh.edu/webentry/image_page.php')

    image_button = driver.find_element_by_name('upload')
    image_button.click()

    imagename_box = driver.find_element_by_name('imagename')
    imagename_box.send_keys(image_name)

    image_file = driver.find_element_by_name('file')
    imagefile_location = os.path.join(submission_dir, file_tup[index][0],file_tup[index][1])
    image_file.send_keys('/home/newuser/AutomatedExperiments/' + imagefile_location)

    upload_button = driver.find_element_by_xpath("//form[@id='mainform']/table//tr[4]/td[2]/input[1]")
    upload_button.click()

    #Create Configuration
    driver.get('http://twonet.cs.uh.edu/webentry/configuration_page.php')

    cfg_button = driver.find_element_by_name('new_cfg')
    cfg_button.click()

    cfgname_box = driver.find_element_by_name('cfg_name')
    cfgname_box.send_keys(image_name)


    select_image = driver.find_element_by_xpath("//select[@id='sel_left']/option[1]")
    select_image.click()

    selectimage_button = driver.find_element_by_xpath("//form[@id='mainform']/table[2]//tr[2]/td[2]/input[1]")
    selectimage_button.click()

    assign_motes_button = driver.find_element_by_name('assign_btn')
    assign_motes_button.click()

    #Assign Motes
    select_image = driver.find_element_by_xpath("//select[@id='sel_image']/option[1]")
    select_image.click()

    selectnode_button = driver.find_element_by_xpath("//form[@id='mainform']/table[1]//tr[2]/td[4]/input[1]")

    for i in range(num_nodes):
        select_node = driver.find_element_by_xpath("//select[@id='sel_left']/option[1]")
        select_node.click()
        selectnode_button.click()

    submitcfg_button = driver.find_element_by_id('submit_btn')
    submitcfg_button.click()

    #Send Task
    driver.get('http://twonet.cs.uh.edu/webentry/task_page.php')

    task_button = driver.find_element_by_name('new_task')
    task_button.click()

    task_box = driver.find_element_by_id('task_name')
    task_box.send_keys(image_name)


    time_slot = driver.find_element_by_css_selector('li.ui-widget-content.ui-selectee')

    ActionChains(driver).drag_and_drop_by_offset(time_slot,0,24*(int(sys.argv[2])-1)).perform()

    #Send Task again
    submit_button = driver.find_element_by_xpath("//form[@id='mainform']/table[1]//tr[3]/td[3]/input[1]")
    submit_button.click()

    driver.get('http://twonet.cs.uh.edu/webentry/task_page.php')

    task_button = driver.find_element_by_name('new_task')
    task_button.click()

    task_box = driver.find_element_by_id('task_name')
    task_box.send_keys(image_name)


    time_slot = driver.find_element_by_css_selector('li.ui-widget-content.ui-selectee')

    ActionChains(driver).drag_and_drop_by_offset(time_slot,0,24*(int(sys.argv[2])-1)).perform()


    submit_button = driver.find_element_by_xpath("//form[@id='mainform']/table[1]//tr[3]/td[3]/input[1]")
    submit_button.click()
