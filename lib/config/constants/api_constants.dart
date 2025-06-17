// Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator, or your PC IP for real device
const String baseUrl = 'http://localhost:8800/taskverse_api';
// const String baseUrl = 'http://10.0.2.2:8800/taskverse_api'; // Android emulator
// const String baseUrl = 'http://127.0.0.1:8800/taskverse_api'; // iOS simulator
// const String baseUrl = 'http://192.168.x.x:8800/taskverse_api'; // real device
const String registerEndpoint = '/register.php';
const String loginEndpoint = '/login.php';
const String usersEndpoint = '/users.php';
const String threadsEndpoint = '/threads.php';
const String projectsEndpoint = '/projects.php';
const String tasksEndpoint = '/tasks.php';
const String projectTasksEndpoint = '/project_tasks.php';
const String notificationsEndpoint = '/notifications.php';
