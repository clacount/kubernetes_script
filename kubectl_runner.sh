#!/bin/bash

# Set some global vars so we know where we're navigating from
from_change_context=false
from_change_namespace=false
updated_context=""
updated_namespace=""
declare -a namespace_list=()

# # Declare a global array to store namespaces
# declare -a namespace_list

# Method to add namespaces to the list
add_to_namespace_list() {
  local new_namespace="$1"

   # Check if the namespace is empty or contains only whitespace
  if [[ -z "${new_namespace// }" ]]; then
    echo "Invalid namespace. Cannot add an empty or whitespace-only namespace."
    return
  fi

  # Check if the namespace is already in the list
  for namespace in "${namespace_list[@]}"; do
    if [[ "$new_namespace" == "$namespace" ]]; then
      return
    fi
  done
  
  namespace_list+=("$new_namespace")
}

# Method used to Find the current context
find_current_context() {
 
 context=$(kubectl config current-context)

}

# Method used to Find the current context
find_current_context() {
 
 echo
 context=$(kubectl config current-context)
 echo '#### The current context is:' \'$context\' '####'
 echo
}

# Method used find the current namespace
find_current_namespace() {

  echo
  name=$(kubectl config view --minify | grep namespace | awk '{ print substr ($0, 16 ) }' )
  echo '#### The current namespace is:' \'$name\' '####'
  echo

}

# Method used to find all the namespaces avaialble
find_all_namespaces() {

  all_namespaces=$(kubectl get namespace)

}

#Helper method used to break out the namespacesz
enter_new_namespace() {

  echo
  echo 'Please enter a namespace'
  read new_namespace
  kubectl config set-context --current --namespace $new_namespace
  echo
  updated_namespace="#### Namespace has been updated to '$new_namespace' ####"
  add_to_namespace_list "$name" # Add current namespace to the list

}

#Method used to either end the application or return back for another option
is_user_finished() {

  echo 
  echo '### To return to the main menu, press Y. Otherwise, press N to close the application? ####'
  echo 'Press Y/N.'
  echo
  read -n 1 close
  
  if [[ $close == 'N' || $close == 'n' ]]
    then
      echo
      clear
      echo 'Thank You!'
      exit 0
    elif [[ $close == 'Y' || $close == 'y' ]]
    then
      echo
      echo 'Returning back to the main menu'
      clear
      main
    else 
    echo
    echo 'Invalid option pressed'
      is_user_finished
  fi
}

# Method used to update the context
change_context() {

  echo
  find_current_context
  echo
  all_contexts=$(kubectl config get-contexts --output=name)
  echo 'All available contexts:' $'\n'"$all_contexts"
  echo
  echo 'Please enter one of the contexts from above:'

  read new_context
  kubectl config use-context $new_context
  echo
  updated_context="#### Context has been updated to '$new_context' ####"
  from_change_context=true
  main
}

# Method used to gather all current namespaces
get_all_namespaces() {
  echo
  find_current_namespace
  echo

  echo 'Do you want to find all namespaces?'
  echo 'Press Y/N'

  read -n 1 find_namespace
  if [[ $find_namespace == 'Y' || $find_namespace == 'y' ]]
  then
    find_all_namespaces
    echo 'All avaialable namespaces:' $'\n'"$all_namespaces"
    echo
    is_user_finished
    elif [[ $find_namespace == 'N' || $find_namespace == 'n' ]]
  then
    echo 'Returning to the main menu.'
    clear
    main
  else
    echo 'Invalid input'
    get_all_namespaces
  fi
}

# Method used to update the namespace
change_namespace() {

  echo
  find_current_namespace
  echo

  echo 'Do you want to find all namespaces?'
  echo 'Press Y/N'

  read -n 1 find_namespace
  if [[ $find_namespace == 'Y' || $find_namespace == 'y' ]]
  then
    find_all_namespaces
    echo 'All avaialable namespaces:' $'\n'"$all_namespaces"
    enter_new_namespace
    add_to_namespace_list "$new_namespace" # Add new namespace to the list
    from_change_namespace=true
    main
  elif [[ $find_namespace == 'N' || $find_namespace == 'n' ]]
  then
    enter_new_namespace
    add_to_namespace_list "$new_namespace" # Add new namespace to the list
    from_change_namespace=true
    main
  else
    echo 'Invalid input'
    change_namespace
  fi
}

# Method used to get all running pods in a namespace
get_running_pods() {
  
  echo
  find_current_namespace
  all_pods=$(kubectl get pods)
    echo 'All available pods:' $'\n'"$all_pods"

  echo 'Do you want to check the pod status for' \'$name\' 'namespace again?'
  echo 'Press Y/N'

  read -n 1 get_pods
  if [[ $get_pods == 'Y' || $get_pods == 'y' ]]
  then 
    get_running_pods
  elif [[ $get_pods == 'N' || $get_pods == 'n' ]]
  then
    echo 'Returning to main menu.'
    clear
    main
  else
    echo 'Invalid input'
    get_running_pods
  fi

}

# Method used to remove the pods and deployments assoicated with the current namespace
remove_pods_and_deployments() {
  find_current_namespace
  echo
  echo "#### WARNING - Are you sure you want to delete all deployments and pods for namespace: '$name' ####"
  echo 'Press Y/N to continue.'
  read -n 1 removal
   if [[ $removal == 'Y' || $removal == 'y' ]]
    then
      echo "Y was pressed. Proceeding with deletion of all pods and deployments for namespace:'$name'"
      kubectl delete --all deployments --namespace=$name
      sleep 2
      kubectl delete --all pods --namespace=$name
      clear
      main
    else [[ $removal == 'N' || $removal == 'n' ]]
      echo
      echo 'N' 'key was pressed. Redirecting back to the main menu'
      clear
      main
  fi
} 

# Method used to remove the current namespace
remove_namespace() {
  local total_namespaces=${#namespace_list[@]}
  local index=1

  for name in "${namespace_list[@]}"; do
    find_current_context
    echo
    echo "#### WARNING - Are you sure you want to delete namespace: '$name' containing all deployments and pods? ####"
    echo 'Press Y/N to continue.'
    read -n 1 removal
    if [[ $removal == 'Y' || $removal == 'y' ]]; then
      echo
      echo "Y was pressed. Starting deletion of namespace: '$name' for context '$context'."
      kubectl delete all --all --namespace $name # Deletes all the pods/deployments
      echo
      echo "All pods and deployments have been deleted."
      sleep 2
      echo
      echo "Beginning deletion of namespace: '$name'."
      kubectl delete ns $name # Deletes the namespace
      
     # Check if it's the last namespace being deleted
      if [[ $index -eq $total_namespaces ]]; then
        echo "Namespace '$name' has been deleted successfully. Returning to the main menu"
        sleep 2
        clear
        main
      else
        echo "Namespace '$name' has been deleted successfully."
        sleep 2
      fi

      index=$((index + 1))
    elif [[ $removal == 'N' || $removal == 'n' ]]; then
      echo
      echo 'N' 'key was pressed. Redirecting back to the main menu'
      clear
      main
    fi
  done
}

# Method used to keep track

#Helper method to get secrets
generate_secrets() {

  echo

  find_current_namespace # Find the current name space so it can be referenced throughout the method.
  echo 'Finding secrets.'
  secrets=$(kubectl get secrets)
  
  found_secrets=$(echo "$secrets" | awk '{if ($1 == "No" && $4 == "found" && $6 == "in") {print "false"; exit;}
  else if (NR==2 && $1 == "artifactory-creds") {print "true"; exit;}
  else if ($1 == "The connection to the server") {print "refused"; exit;} 
  else if ($2 == "connection" && $5 == "server" && $11 == "refused") {print "refused"; exit;}}')

  if [[ $found_secrets == "true" ]] 
  then
    echo "Secrets have already been generated and are found for the current namespace."
    is_user_finished
  elif [[ $found_secrets == "false" ]] 
  then
    echo "#### There are no secrets present is this namespace. Beginning secret generation. ####"
      kubectl create secret generic artifactory-creds --from-file=.dockerconfigjson=temp-secret.txt --type kubernetes.io/dockerconfigjson
      kubectl create secret generic site-config-secret --from-literal=ARTIFACTORY_TOKEN=$ARTIFACTORY_KEY --from-literal=ARTIFACTORY_KEY=$ARTIFACTORY_TOKEN  --from-literal=ARTIFACTORY_USER_NAME=$ARTIFACTORY_USER_NAME
      echo
      is_user_finished
  elif [[ $found_secrets == "refused" ]] 
  then
    echo "#### NOTE ####"
    echo "k8s is not running. Please check docker and retry again."
    main
  fi
}

stop_port_forwarding() {
  echo "Stopping port forwarding with pid $mcslite_port_forward_pid"
  kill "$mcslite_port_forward_pid"
  mcs_pid=$(ps aux | grep mcs | awk '{ print $2; exit }')
  echo "Stopping MCSLite with PID $mcs_pid"
  ps aux | grep mcs | awk '{ print $2; exit }' | xargs kill
  is_user_finished
}

# Method used to launch a cluster 
start_cluster() {
is_from_cluster=true
secrets_generated_by_cluster_function=false
  echo 'Starting up new cluster'
  echo 'Checking for secrets' 
  generate_secrets
  if [ $secrets_generated_by_cluster_function = true ]
  then 
    echo 'Secrets have been generated'
    main
  fi
  
}

# Method to kick off k9s
start_k9s() {
  start=$(k9s)
  clear
  main
}

# Method to display all namespaces added to the list
namespaces_changed() {
  echo
  echo "#### Namespaces added to the list: ####"
  for namespace in "${namespace_list[@]}"; do
    # Skip empty or whitespace-only namespaces
    if [[ -n "${namespace// }" ]]; then
      echo "$namespace"
    fi
  done
  echo "#####################################"
  echo
  read -n 1 -s -r -p "Press any key to continue..."
  clear
  main
}

# Main Controller 
main() {
 
  #cat logo.txt
  # Let's first check to see if we've transitioned from context/namespace states. If so, display things slightly differently to the user.
  if [ $from_change_context == true ] 
  then
    clear
    #cat logo.txt
    echo
    echo
    echo "$updated_context"
    echo
    echo
    from_change_context=false
    updated_context=""
  fi

   if [ $from_change_namespace == true ] 
  then
    clear
    echo
    echo
    echo "$updated_namespace"
    echo
    echo
    from_change_namespace=false
    updated_namespace=""
  fi

  # List out all the available options for the user to select from.
  echo 'Please begin by selecting an option:'
  echo '  1: Find current context'
  echo '  2: Change context'
  echo '  3: Find current namespace'
  echo '  4: Get all namespaces'
  echo '  5: Change namespace'
  echo '  6: Find all running pods for current namespce'
  echo '  7: Remove all deployments and pods for current namespace'
  echo '  8: Remove namespaces, deployments, and pods from this session'
  echo '  9: Generate secrets - ### NOT AVAILABLE FOR EMULATION CONTEXT ###'
  #echo ' 10: Start MCSLite'
  #echo ' 11: Uninstall MCSLite'
  #echo ' 12: Start local cluster - ### NOT WORKING YET ###'
  echo ' 10: Launch k9s'
  echo ' 11: See all namespaces changed within this session'
  echo ' 12: Quit'

  read user_selection

  if [[ $user_selection == 1 ]]
  then
    find_current_context
    is_user_finished
 
  elif [[ $user_selection == 2 ]]
  then
    from_change_context=true
    change_context #Runs method to change the context.

  elif [[ $user_selection == 3 ]]
  then
    find_current_namespace
    is_user_finished

  elif [[ $user_selection == 4 ]]
  then
    get_all_namespaces #Runs method that fetches all available namespaces.
    
  elif [[ $user_selection == 5 ]]
  then
    change_namespace #Runs method that allows the user to change the namespace.

  elif [[ $user_selection == 6 ]]
 then
    get_running_pods #Runs method that displays the current pods running in the namespace.

  elif [[ $user_selection == 7 ]]
  then
    remove_pods_and_deployments # Runs method that removes the current namespace.

  elif [[ $user_selection == 8 ]]
  then
    remove_namespace # Runs method that removes the current namespace.

  elif [[ $user_selection == 9 ]]
  then
    generate_secrets # Runs method that will generate secrets.

   #elif [[ $user_selection == 10 ]]
  #then
    #start_mcs_lite # Runs method that will start MCSLite using the install.sh script.

  #elif [[ $user_selection == 11 ]]
  #then
    #reinstall_msclite # Runs method that will uninstall MCSLite using the install.sh script.

 # elif [[ $user_selection == 12 ]]
  #then
    #start_cluster # Runs method that will start a local cluster.

  elif [[ $user_selection == 10 ]]
  then
    start_k9s
  
  elif [[ $user_selection == 11 ]]
  then
    namespaces_changed
  
  elif [[ $user_selection == 12 ]]
  then
  clear
    echo "Exiting application. Thank you!"
    exit 0 # Gracefully prompts the user to exit the application.

  else
   echo
   clear
   echo 'An invalid key was entered'
   main
  fi
}
add_to_namespace_list $(kubectl config view --minify | grep namespace | awk '{ print substr ($0, 16 ) }' )
main
