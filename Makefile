.PHONY: qemu stm32

PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)

build-linux:
	@echo "Rebuilding Linux and afboot-stm32..."

	@$(MAKE) -C $(PROJECT_DIR)/buildroot-2026.02-rc2 linux-rebuild
	@$(MAKE) -C $(PROJECT_DIR)/buildroot-2026.02-rc2 afboot-stm32-rebuild

build-run:
	@echo "Rebuilding Linux and afboot-stm32..."

	@$(MAKE) -C $(PROJECT_DIR)/buildroot-2026.02-rc2 linux-rebuild
	@$(MAKE) -C $(PROJECT_DIR)/buildroot-2026.02-rc2 afboot-stm32-rebuild

	@echo "Running stm32 target..."
	@$(MAKE) stm32

qemu:
	@echo "Run qemu command"

	@BIN_ADDR=0x08000000; \
	DTB_ADDR=0x08004000; \
	XIP_ADDR=0x0800C000; \
	ROOTFS_ADDR=0x08180000; \
	\
	BIN=$(PROJECT_DIR)/buildroot-2026.02-rc2/output/images/stm32f429i-disco.bin; \
	DTB=$(PROJECT_DIR)/buildroot-2026.02-rc2/output/images/stm32f429-disco.dtb; \
	XIP=$(PROJECT_DIR)/buildroot-2026.02-rc2/output/images/xipImage; \
	ROOTFS=$(PROJECT_DIR)/buildroot-2026.02-rc2/output/images/rootfs.romfs; \
	\
	bin_size=$$(stat -c%s $$BIN); \
	dtb_size=$$(stat -c%s $$DTB); \
	xip_size=$$(stat -c%s $$XIP); \
	rootfs_size=$$(stat -c%s $$ROOTFS); \
	\
	bin_end=$$((BIN_ADDR + bin_size)); \
	dtb_end=$$((DTB_ADDR + dtb_size)); \
	xip_end=$$((XIP_ADDR + xip_size)); \
	rootfs_end=$$((ROOTFS_ADDR + rootfs_size)); \
	\
	printf "BIN:     0x%X -> 0x%X (size %d)\n" $$BIN_ADDR $$bin_end $$bin_size; \
	printf "DTB:     0x%X -> 0x%X (size %d)\n" $$DTB_ADDR $$dtb_end $$dtb_size; \
	printf "XIP:     0x%X -> 0x%X (size %d)\n" $$XIP_ADDR $$xip_end $$xip_size; \
	printf "ROOTFS:  0x%X -> 0x%X (size %d)\n" $$ROOTFS_ADDR $$rootfs_end $$rootfs_size; \
	\
	if [ $$bin_end -gt $$DTB_ADDR ]; then \
		echo "❌ BIN overlaps DTB"; exit 1; \
	fi; \
	if [ $$dtb_end -gt $$XIP_ADDR ]; then \
		echo "❌ DTB overlaps XIP"; exit 1; \
	fi; \
	if [ $$xip_end -gt $$ROOTFS_ADDR ]; then \
		echo "❌ XIP overlaps ROOTFS"; exit 1; \
	fi; \
	if [ $$ROOTFS_end -gt $$0x081FFFFF ]; then \
		echo "❌ ROOTFS overlaps FLASH"; exit 1; \
	fi; \
	echo "✅ No overlap detected"; \
	\
	$(PROJECT_DIR)/qemu-fork/build/qemu-system-arm -M stm32f429discovery \
		-serial stdio -display none \
		-device loader,file=$$BIN,addr=$$BIN_ADDR \
		-device loader,file=$$DTB,addr=$$DTB_ADDR \
		-device loader,file=$$XIP,addr=$$XIP_ADDR \
		-device loader,file=$$ROOTFS,addr=$$ROOTFS_ADDR \
		-s

stm32:
	@echo "Build stm32"
	$(PROJECT_DIR)/buildroot-2026.02-rc2/board/stmicroelectronics/stm32f429-disco/flash.sh $(PROJECT_DIR)/buildroot-2026.02-rc2/output stm32f429discovery