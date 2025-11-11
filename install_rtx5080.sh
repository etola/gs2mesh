#!/bin/bash

# GS2Mesh Installation Script for RTX 5080 (Blackwell Architecture)
# For CUDA 12.8+ / RTX 5080
# Uses PyTorch NIGHTLY with potential support for sm_120 (Blackwell)

set -e  # Exit on error

echo "========================================"
echo "GS2Mesh Installation Script"
echo "RTX 5080 (Blackwell) - NIGHTLY Edition"
echo "========================================"
echo ""
echo "WARNING: This uses PyTorch nightly builds which may be unstable"
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Installing in directory: $SCRIPT_DIR"
echo ""

# Step 1: Create conda environment
echo "Step 1: Creating conda environment 'gs2mesh' with Python 3.11..."
echo "Note: Using Python 3.11 for best compatibility with nightly PyTorch"
if conda env list | grep -q "^gs2mesh "; then
    echo "Warning: Environment 'gs2mesh' already exists."
    read -p "Do you want to remove and recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        conda remove -n gs2mesh --all -y
    else
        echo "Skipping environment creation. Activating existing environment..."
        eval "$(conda shell.bash hook)"
        conda activate gs2mesh
        echo "Environment activated. Continuing with remaining steps..."
        SKIP_CONDA_INSTALL=true
    fi
fi

if [ -z "$SKIP_CONDA_INSTALL" ]; then
    conda create --name gs2mesh python=3.11 -y
    echo "✓ Environment created successfully"
    echo ""

    # Activate the environment
    echo "Step 2: Activating gs2mesh environment..."
    eval "$(conda shell.bash hook)"
    conda activate gs2mesh
    echo "✓ Environment activated"
    echo ""

    # Step 2.5: Set CUDA 13.0 environment (matching PyTorch cu130)
    echo "Step 2.5: Configuring CUDA 13.0 environment..."
    export CUDA_HOME=/usr/local/cuda-13.0
    export PATH=/usr/local/cuda-13.0/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:$LD_LIBRARY_PATH
    conda env config vars set CUDA_HOME=/usr/local/cuda-13.0 -n gs2mesh
    echo "✓ CUDA 13.0 environment configured"
    echo "  CUDA_HOME: /usr/local/cuda-13.0"
    echo ""
    
    # Step 3: Install PyTorch with CUDA 13.0 support (matching CUDA 13.0 toolkit)
    echo "Step 3: Installing PyTorch NIGHTLY with CUDA 13.0 support..."
    echo "This may take several minutes..."
    echo "  Note: Using cu130 (CUDA 13.0) matching your CUDA 13.0 toolkit and driver"
    
    # Install PyTorch nightly with CUDA 13.0 support - perfect match for RTX 5080
    pip3 install --upgrade --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu130
    
    echo "✓ PyTorch nightly with CUDA 13.0 installed successfully"
    echo ""
    
    # Install COLMAP separately via conda
    echo "Step 3.5: Installing COLMAP..."
    conda install colmap -c conda-forge -y
    echo "✓ COLMAP installed successfully"
    echo ""

    # Step 4: Set environment variables for RTX 5080 / Blackwell
    echo "Step 4: Setting CUDA architecture flags for RTX 5080..."
    # Set both sm_90 and sm_120 for best compatibility with RTX 5080
    # sm_90: Hopper architecture (fallback compatibility)
    # sm_120: Blackwell architecture (RTX 5080 native)
    export TORCH_CUDA_ARCH_LIST="9.0;12.0"
    conda env config vars set TORCH_CUDA_ARCH_LIST="9.0;12.0" -n gs2mesh
    echo "✓ CUDA architecture flags set to sm_90 and sm_120"
    echo "  Note: Compiling for both Hopper (sm_90) and Blackwell (sm_120) architectures"
    echo ""

    # Step 5: Install additional dependencies from requirements.txt
    echo "Step 5: Installing additional dependencies from requirements.txt..."
    
    # Install Open3D with a version compatible with Python 3.11
    pip install -r requirements.txt
    
    echo "✓ Additional dependencies installed successfully"
    echo ""
fi

# Step 6: Download DLNR Stereo weights
echo "Step 6: Downloading DLNR Stereo weights..."
mkdir -p third_party/DLNR/pretrained
cd third_party/DLNR/pretrained

if [ ! -f "DLNR_Middlebury.pth" ]; then
    echo "Downloading DLNR_Middlebury.pth..."
    wget https://github.com/David-Zhao-1997/High-frequency-Stereo-Matching-Network/releases/download/v1.0.0/DLNR_Middlebury.pth
    echo "✓ DLNR_Middlebury.pth downloaded"
else
    echo "✓ DLNR_Middlebury.pth already exists, skipping..."
fi

if [ ! -f "DLNR_SceneFlow.pth" ]; then
    echo "Downloading DLNR_SceneFlow.pth..."
    wget https://github.com/David-Zhao-1997/High-frequency-Stereo-Matching-Network/releases/download/v1.0.0/DLNR_SceneFlow.pth
    echo "✓ DLNR_SceneFlow.pth downloaded"
else
    echo "✓ DLNR_SceneFlow.pth already exists, skipping..."
fi

cd "$SCRIPT_DIR"
echo ""

# Step 7: Download GroundingDINO weights
echo "Step 7: Downloading GroundingDINO weights (for automatic masking)..."
mkdir -p third_party/GroundingDINO/weights
cd third_party/GroundingDINO/weights

if [ ! -f "groundingdino_swint_ogc.pth" ]; then
    echo "Downloading groundingdino_swint_ogc.pth..."
    wget https://github.com/IDEA-Research/GroundingDINO/releases/download/v0.1.0-alpha/groundingdino_swint_ogc.pth
    echo "✓ GroundingDINO weights downloaded"
else
    echo "✓ groundingdino_swint_ogc.pth already exists, skipping..."
fi

cd "$SCRIPT_DIR"
echo ""

# Step 8: Optional - Download SAM2 weights (optional, as they auto-download)
echo "Step 8: SAM2 weights (optional)..."
echo "Note: SAM2 weights will auto-download via Huggingface when needed."
read -p "Do you want to download SAM2 weights locally? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p third_party/segment-anything-2/checkpoints
    cd third_party/segment-anything-2/checkpoints
    if [ ! -f "sam2_hiera_large.pt" ]; then
        echo "Downloading sam2_hiera_large.pt..."
        wget https://dl.fbaipublicfiles.com/segment_anything_2/072824/sam2_hiera_large.pt
        echo "✓ SAM2 weights downloaded"
    else
        echo "✓ sam2_hiera_large.pt already exists, skipping..."
    fi
    cd "$SCRIPT_DIR"
else
    echo "Skipping SAM2 local weights download."
fi
echo ""

# Completion message
echo "========================================"
echo "✓ Installation Complete!"
echo "========================================"
echo ""
echo "Your system information:"
echo "  - CUDA Version: 13.0 (Driver)"
echo "  - GPU: NVIDIA GeForce RTX 5080 (Blackwell/sm_120)"
echo "  - PyTorch: Nightly with CUDA 13.0 support"
echo "  - CUDA Extensions compiled for: sm_90 (Hopper) and sm_120 (Blackwell/RTX 5080)"
echo ""
echo "IMPORTANT: You must reactivate the environment for settings to take effect:"
echo "  conda deactivate"
echo "  conda activate gs2mesh"
echo ""
echo "To test the installation, run:"
echo "  python -c 'import torch; print(f\"PyTorch: {torch.__version__}\"); print(f\"CUDA Available: {torch.cuda.is_available()}\"); print(f\"CUDA Version: {torch.version.cuda}\"); print(f\"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}\")'"
echo ""
echo "⚠️  IMPORTANT NOTES FOR RTX 5080:"
echo "  1. Using PyTorch NIGHTLY with CUDA 13.0"
echo "  2. CUDA 13.0 toolkit, driver, and PyTorch all aligned"
echo "  3. CUDA extensions compiled for both sm_90 (Hopper) and sm_120 (Blackwell/RTX 5080)"
echo "  4. This setup provides optimal performance for RTX 5080"
echo "  5. If you encounter issues:"
echo "     - Try updating PyTorch nightly: pip install --upgrade --pre torch --index-url https://download.pytorch.org/whl/nightly/cu130"
echo ""

