#!/bin/bash
# Set the aws.env file path to a directory above the current directory
aws_env_file_path="../aws.env"

# Function to determine the Python executable name
determine_python_executable() {
  if command -v python3 &> /dev/null; then
    PYTHON_EXECUTABLE="python3"
  elif command -v python &> /dev/null; then
    PYTHON_EXECUTABLE="python"
  else
    echo "Python executable not found"
    exit 1
  fi
}

# Function to determine the platform
determine_platform() {
  ACTIVATE_SCRIPT="activate"
  if [ "$PLATFORM" == "Linux" ]; then
    VENV_DIR="venv/bin"
  elif [ "$PLATFORM" == "Windows"]; then
    VENV_DIR="venv/Scripts"
  else
    echo "Unsupported platform"
    exit 1
  fi
}

# Function to create the virtual environment
create_virtual_environment() {
  echo "Creating virtual environment..."
  $PYTHON_EXECUTABLE -m venv venv
}

# Function to activate the virtual environment
activate_virtual_environment() {
  echo "Activating virtual environment..."
  source "$VENV_DIR/$ACTIVATE_SCRIPT"
}

# Function to set the necessary environment variables
set_environment_variables() {
  echo "Setting environment variables..."
  sed -i 's/\r//' "$aws_env_file_path"
  if [[ "$PLATFORM" == "Windows" ]]; then
    # Windows
    sed 's/\r$//' "$aws_env_file_path" | while read -r line || [[ -n "$line" ]]; do
      export "$line"
    done
  else
    # Linux
    export $(grep -v '^#' "$aws_env_file_path" | xargs)
  fi
}

#Function to download and install Terraform
download_and_install_terraform() {
  TF_VERSION="1.4.4"
if [ "$PLATFORM" == "Linux" ]; then
  curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
  curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS"
  sha256sum --check --ignore-missing "terraform_${TF_VERSION}_SHA256SUMS"
  unzip "terraform_${TF_VERSION}_linux_amd64.zip"
  mv terraform "$VENV_DIR/"
  rm "terraform_${TF_VERSION}_linux_amd64.zip" "terraform_${TF_VERSION}_SHA256SUMS"
elif [ "$PLATFORM" == "Windows" ]; then
  curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_windows_amd64.zip"
  curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS"
  grep "terraform_${TF_VERSION}_windows_amd64.zip" "terraform_${TF_VERSION}_SHA256SUMS" > "terraform_${TF_VERSION}_windows_SHA256SUMS"
  CertUtil -hashfile "terraform_${TF_VERSION}_windows_amd64.zip" SHA256 | findstr /r /c:"^[A-Fa-f0-9]*$" > "terraform_${TF_VERSION}_windows_amd64_checksum.txt"
  if ! cmp --silent "terraform_${TF_VERSION}_windows_SHA256SUMS" "terraform_${TF_VERSION}_windows_amd64_checksum.txt"; then
    echo "Checksum validation failed. Exiting."
    exit 1
  fi
  unzip "terraform_${TF_VERSION}_windows_amd64.zip"
  mv terraform.exe "$VENV_DIR/"
  rm "terraform_${TF_VERSION}_windows_amd64.zip" "terraform_${TF_VERSION}_SHA256SUMS" "terraform_${TF_VERSION}_windows_SHA256SUMS" "terraform_${TF_VERSION}_windows_amd64_checksum.txt"
fi
}

# Function to install AWS CLI on Linux
install_aws_cli_linux() {
  if [ ! -d "$VENV_DIR/aws-cli" ]; then
    echo "Installing AWS CLI on Linux..."

    # Download the AWS CLI installation script
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

    # Install unzip if it's not installed
    if ! command -v unzip &> /dev/null; then
      sudo apt-get update
      sudo apt-get install -y unzip
    fi

    # Unzip the AWS CLI installation package
    unzip awscliv2.zip

    # Install the AWS CLI
    sudo ./aws/install --install-dir "$VENV_DIR/aws-cli" --bin-dir "$VENV_DIR"
    rm awscliv2.zip
  else
    echo "AWS CLI already installed."
  fi
}

# Function to install AWS CLI on Windows (Git Bash)
install_aws_cli_windows() {
  if [ ! -d "$VENV_DIR/aws-cli" ]; then
    echo "Installing AWS CLI on Windows..."

    # Download the AWS CLI installation script
    curl "https://awscli.amazonaws.com/AWSCLIV2.msi" -o "AWSCLIV2.msi"

    # Install the AWS CLI
    msiexec.exe /i AWSCLIV2.msi /qn /norestart TARGETDIR="$(pwd)/$VENV_DIR/aws-cli"

    # Create a symbolic link to the AWS CLI executable in the virtual environment's bin folder
    ln -s "$(pwd)/$VENV_DIR/aws-cli/aws.exe" "$(pwd)/$VENV_DIR/aws"
    rm AWSCLIV2.msi
  else
    echo "AWS CLI already installed."
  fi
}




# Function to download and install AWS CLI
download_and_install_aws_cli(){
    # Determine the platform and install AWS CLI accordingly
if [ "$PLATFORM" == "Linux" ]; then
  install_aws_cli_linux
elif [ "$PLATFORM" == "Windows" ]; then
  install_aws_cli_windows
else
  echo "Unsupported platform"
  exit 1
fi
echo "AWS CLI installation complete"
}


# Function to run Terraform commands
run_terraform() {
  terraform init
  terraform plan -out=tfplan

  # Ask for user input to apply the changes or destroy resources
  read -p "Do you want to apply the changes (a), destroy resources (d), or do nothing (n)? (a/d/n): " user_action

  if [ "$user_action" == "a" ] || [ "$user_action" == "A" ]; then
    terraform apply -auto-approve tfplan
  elif [ "$user_action" == "d" ] || [ "$user_action" == "D" ]; then
    terraform destroy -auto-approve
  else
    echo "No action taken."
  fi
}


# Function to determine the platform
determine_platform() {
  case "$(uname -s)" in
    Linux)
      PLATFORM="Linux"
      VENV_DIR="venv/bin"
      ACTIVATE_SCRIPT="activate"
      ;;
    MINGW64_NT-10.0 | MINGW32_NT-10.0)
      PLATFORM="Windows"
      VENV_DIR="venv/Scripts"
      ACTIVATE_SCRIPT="activate"
      ;;
    *)
      echo "Unsupported platform"
      exit 1
      ;;
  esac
}

# Function to deactivate the virtual environment and clean up
cleanup() {
  if [ "$PLATFORM" == "Linux" ]; then
    deactivate
  elif [ "$PLATFORM" == "Windows" ]; then
    deactivate.bat
  fi
}

# Main script
determine_python_executable
determine_platform
echo "Platform: $PLATFORM"
if [ ! -d "$VENV_DIR" ]; then
  create_virtual_environment
fi
activate_virtual_environment

# Download and install Terraform and AWS CLI
download_and_install_terraform
download_and_install_aws_cli

set_environment_variables
if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
    echo "Aws Access Key not found"
else
    echo "Aws Access Key Loaded"
fi

if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
    echo "Aws Secret Key not found"
else
    echo "Aws Secret Key Loaded"
fi
aws sts get-caller-identity

run_terraform
cleanup
