import torch.distributed as dist

def init_rccl(world_size, rank):
    # dist.init_process_group(backend="nccl", init_method="env://", world_size=world_size, rank=rank)
    pass
